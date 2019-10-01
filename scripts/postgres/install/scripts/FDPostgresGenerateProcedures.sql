CREATE OR REPLACE VIEW FD.VTESTAUTOMATIONRESULT
AS select test_run.project_id,
       test_run.environment_id,
       test_run.instance_id,
       test_run.project_stream_id,
       test_run.test_type_id,
       test_run.start_time as test_date, 
       ts.Test_set_id,
       ts.test_set_name,
       td.test_definition_id,
       td.test_definition_name,
       tr.test_case_name,
       tr.status,
       tr.duration,
       tr.MinRespTime,
       tr.MaxRespTime,
       tr.AvgRespTime,
       e.environment_name,
       e.environment_code,
       tdr.start_time,
       f.folder_name
from FD.TEST_RESULT tr, FD.TEST_DEFINITION_RUN tdr, FD.TEST_DEFINITION td, FD.TEST_SET_RUN tsr, FD.TEST_SET ts, FD.TEST_RUN test_run, FD.ENVIRONMENT e, FD.PROJECT p, FD.FOLDER f
where tr.test_definition_run_id = tdr.test_definition_run_id and
      tdr.Test_definition_id = td.Test_definition_id and
      tdr.test_set_run_id = tsr.test_set_run_id and
      tsr.test_set_id = ts.test_set_id and
      tsr.Test_run_id = test_run.Test_run_id and
      test_run.environment_id = e.environment_id and
      test_run.project_id = p.project_id and
      p.folder_id = f.folder_id;

CREATE OR REPLACE VIEW FD.VRELEASESNAPSHOTENVIRONMENT
AS SELECT execution.rel_definition_id,
  execution.ENVIRONMENT_ID,
  execution.rel_snapshot_id,
  execution.UPDATED_BY,
  execution.UPDATED_ON,
  execution.on_deck_snapshot_id,
  env.environment_code,
  env.environment_name,
  rs.Rel_snapshot,
  on_deck_rs.Rel_snapshot on_desck_rel_snapshot,
  exec_id,
  execution.start_time,
  execution.end_time,
  ps.sequence_number
FROM
  (SELECT deploy_exec.rel_definition_id,
    stage_exec.ENVIRONMENT_ID,
    stage_exec.rel_snapshot_id,
    stage_exec.UPDATED_BY,
    stage_exec.UPDATED_ON,
    deploy_exec.exec_id,
    stage_exec.start_time,
    stage_exec.end_time,
    stage_exec.pipeline_definition_id,
    (SELECT rel_snapshot_id
    FROM fd.pipeline_stage_exec
    WHERE pipeline_stage_exec_id =
      (SELECT MAX(pipeline_stage_exec_id)
      FROM fd.pipeline_stage_exec min_exec,
        fd.rel_snapshot min_snap
      WHERE min_exec.rel_snapshot_id      = min_snap.rel_snapshot_id
      AND min_exec.pipeline_stage_exec_id > deploy_exec.exec_id
      AND min_snap.rel_definition_id      = deploy_exec.rel_definition_id
      AND min_exec.ENVIRONMENT_ID         = deploy_exec.ENVIRONMENT_ID
      AND min_exec.execution_status in ('RUNNING_GATES','GATES_COMPLETE','RUNNING_STEPS')
      )
    ) on_deck_snapshot_id
  FROM fd.pipeline_stage_exec stage_exec,
    (SELECT snap.rel_definition_id,
      exec.ENVIRONMENT_ID,
      MAX(exec.pipeline_stage_exec_id) exec_id
    FROM fd.pipeline_stage_exec EXEC,
      fd.rel_snapshot snap
    WHERE exec.rel_snapshot_id = snap.rel_snapshot_id
    AND exec.execution_status  = 'SUCCESSFUL'
    GROUP BY snap.rel_definition_id,
      exec.ENVIRONMENT_ID
    ) deploy_exec
  WHERE stage_exec.pipeline_stage_exec_id = deploy_exec.exec_id
  ) execution
  left outer join fd.Rel_snapshot on_deck_rs on execution.on_deck_snapshot_id = on_deck_rs.rel_snapshot_id,
  fd.Environment env,
  fd.Rel_snapshot rs,
  fd.pipeline_definition pd,
  fd.pipeline_stage ps
WHERE execution.ENVIRONMENT_ID    = env.ENVIRONMENT_ID
AND execution.rel_snapshot_id     = rs.rel_snapshot_id
AND pd.pipeline_definition_id = execution.pipeline_definition_id
AND pd.active_pipeline_version_id = ps.pipeline_version_id
and ps.environment_id = execution.ENVIRONMENT_ID;

CREATE OR REPLACE VIEW FD.MVPROJECTTASKTIMELINEALL (ID, PROJECT_ID, WORKFLOW_TYPE, DURATION, DURATION_HOURS, DURATION_MINUTES, START_TIME, END_TIME, TASK_DATE, WORKFLOW_ID, STATUS, PROJECT_VERSION, ENVIRONMENT_CODE, INSTANCE_CODE, ENVIRONMENT_ID, INSTANCE_ID, FOLDER_NAME, PROJECT_NAME, WORKFLOW_NAME, FOLDER_ID, ENV_INST_ID, STREAM_NAME, PROJECT_WORKFLOW_ID, PROJECT_VERSION_ID, PROJECT_STREAM_ID) AS
  SELECT we.WorkFlow_execution_id id,
    we.project_id,
    pw.project_workflow_type workflow_type,
    trunc(EXTRACT(EPOCH FROM we.end_time - we.start_time)) duration, 
    trunc(EXTRACT(EPOCH FROM we.end_time - we.start_time)/3600) duration_hours,
    trunc(EXTRACT(EPOCH FROM we.end_time - we.start_time)/60) -
    trunc(EXTRACT(EPOCH FROM we.end_time - we.start_time)/3600)*60 duration_minutes ,
    we.start_time,
    we.end_time,
    CAST(we.start_time AS DATE) task_date,
    pw.workflow_id,
    SUBSTR(we.execution_status,1,1) status,
    pv.project_version_name project_version,
    env.environment_code,
    ins.instance_code,
    we.environment_id,
    we.instance_id,
    f.folder_name,
    p.project_name,
    w.workflow_name,
    p.folder_id,
    env_inst.env_inst_id,
    ps.stream_name,
    pw.project_workflow_id,
    pv.project_version_id,
    ps.project_stream_id
  FROM FD.Workflow_execution we
  LEFT OUTER JOIN FD.environment_Instance env_inst
  ON we.environment_id = env_inst.environment_id
  AND we.instance_id   = env_inst.instance_id,
    FD.project_workflow pw,
    FD.project_version pv
  LEFT OUTER JOIN FD.project_stream ps
  ON pv.project_stream_id = ps.project_stream_id,
    FD.environment env,
    FD.instance ins,
    FD.folder f,
    FD.project p,
    FD.workflow w
  WHERE we.project_workflow_id         = pw.project_workflow_id
  AND we.project_version_id            = pv.project_version_id
  AND we.environment_id                = env.environment_id
  AND we.instance_id                   = ins.instance_id
  AND we.project_id                    = p.project_id
  AND p.folder_id                      = f.folder_id
  AND pw.workflow_id                   = w.workflow_id
  AND we.end_time                     IS NOT NULL
  AND we.start_time                   IS NOT NULL
  AND we.parent_workflow_execution_id IS NULL
  AND w.workflow_type                 IN ('BUILD', 'DEPLOY', 'TEST', 'UTILITY');
      

CREATE OR REPLACE VIEW FD.VPROJECTTASKTIMELINEALL
AS select ID,PROJECT_ID,WORKFLOW_TYPE,DURATION,DURATION_HOURS,DURATION_MINUTES,START_TIME,END_TIME,TASK_DATE,WORKFLOW_ID,STATUS,PROJECT_VERSION,ENVIRONMENT_CODE,INSTANCE_CODE,ENVIRONMENT_ID,INSTANCE_ID,FOLDER_NAME,PROJECT_NAME,WORKFLOW_NAME,FOLDER_ID,ENV_INST_ID,STREAM_NAME,PROJECT_WORKFLOW_ID,PROJECT_VERSION_ID,PROJECT_STREAM_ID from FD.MVProjectTaskTimeLineAll;

CREATE OR REPLACE VIEW FD.VPROJECTTASKTIMELINE
AS select ID,PROJECT_ID,WORKFLOW_TYPE,DURATION,DURATION_HOURS,DURATION_MINUTES,START_TIME,END_TIME,TASK_DATE,WORKFLOW_ID,STATUS,PROJECT_VERSION,ENVIRONMENT_CODE,INSTANCE_CODE,ENVIRONMENT_ID,INSTANCE_ID,FOLDER_NAME,PROJECT_NAME,WORKFLOW_NAME,FOLDER_ID,ENV_INST_ID,STREAM_NAME from FD.VProjectTaskTimeLineAll
where workflow_type in ('BUILD', 'DEPLOY');

-- ignore nulls - still need to determine if this will hurt us.
CREATE OR REPLACE VIEW FD.VCURRENTPROJECTTASK
AS select
       we.workflow_execution_id,
       we.project_id,
       we.project_workflow_id,
       we.start_time,
       we.execution_status,
       we.project_version_id,
       we.environment_id,
       we.instance_id,
       we.last_exec_id,
       we.last_exec_start_time,
       we.last_exec_end_time,
       we.last_exec_status,
       we.last_exec_environment_id,
       we.last_exec_instance_id,
       p.project_name,
       pw.workflow_id,
       w.workflow_type,
       w.workflow_name,
       (DATE_PART('day', current_timestamp::timestamp - we.start_time::timestamp) * 24 + 
               DATE_PART('hour', current_timestamp::timestamp - we.start_time::timestamp)) * 60 Duration_hours,
       (DATE_PART('day', current_timestamp::timestamp - we.start_time::timestamp) * 24 + 
               DATE_PART('hour', current_timestamp::timestamp - we.start_time::timestamp)) * 60 +
               DATE_PART('minute', current_timestamp::timestamp - we.start_time::timestamp) Duration_minutes,
       env_inst.env_inst_id,
       env.ENVIRONMENT_NAME,
       ins.instance_name,
       env.ENVIRONMENT_CODE,
       ins.INSTANCE_CODE,
       (DATE_PART('day', we.last_exec_end_time::timestamp - we.last_exec_start_time::timestamp) * 24 + 
               DATE_PART('hour', we.last_exec_end_time::timestamp - we.last_exec_start_time::timestamp)) * 60 last_hour_duration,
       (DATE_PART('day', we.last_exec_end_time::timestamp - we.last_exec_start_time::timestamp) * 24 + 
               DATE_PART('hour', we.last_exec_end_time::timestamp - we.last_exec_start_time::timestamp)) * 60 +
               DATE_PART('minute', we.last_exec_end_time::timestamp - we.last_exec_start_time::timestamp) last_minute_duration,
       (DATE_PART('day', current_timestamp::timestamp - we.last_exec_end_time::timestamp) * 24 + 
               DATE_PART('hour', current_timestamp::timestamp - we.last_exec_end_time::timestamp)) * 60 last_hour_ago,
       (DATE_PART('day', current_timestamp::timestamp - we.last_exec_end_time::timestamp) * 24 + 
               DATE_PART('hour', current_timestamp::timestamp - we.last_exec_end_time::timestamp)) * 60 +
               DATE_PART('minute', current_timestamp::timestamp - we.last_exec_end_time::timestamp) last_minute_ago,
       substr(we.last_exec_status,1,1) last_exec_state_id,
       last_env.ENVIRONMENT_NAME last_ENVIRONMENT_NAME,
       last_ins.instance_name last_instance_name,
       last_env.ENVIRONMENT_CODE last_ENVIRONMENT_CODE,
       last_ins.INSTANCE_CODE last_INSTANCE_CODE,
       pv.project_version_name project_version,
       f.folder_name,
       f.folder_id,
       (success_last_count/total_last_count)*100 SuccessRatio
from (
select workflow_execution_id,
       project_id,
       project_workflow_id,
       start_time,
       execution_status,
       project_version_id,
       environment_id,
       instance_id,
       LEAD(case when execution_status='Running' then null else workflow_execution_id end) OVER (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc) last_exec_id,
       LEAD(case when execution_status='Running' then null else start_time end) OVER (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc) last_exec_start_time,
       LEAD(case when execution_status='Running' then null else end_time end) OVER (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc) last_exec_end_time,
       LEAD(case when execution_status='Running' then null else execution_status end) OVER (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc) last_exec_status,
       LEAD(case when execution_status='Running' then null else environment_id end) OVER (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc) last_exec_environment_id,
       LEAD(case when execution_status='Running' then null else instance_id end) OVER (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc) last_exec_instance_id,
       count(1)  over (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc
                                                                  ROWS BETWEEN CURRENT ROW AND 10 FOLLOWING) total_last_count,
       sum(case execution_status when 'Failure' then 0 else 1 end) over (PARTITION BY project_id,  project_workflow_id order by workflow_execution_id desc
                                                                  ROWS BETWEEN CURRENT ROW AND 10 FOLLOWING) success_last_count
from FD.WORKFLOW_EXECUTION
where parent_workflow_execution_id is null 
and (project_id,project_workflow_id) IN
    (SELECT DISTINCT project_id,
      project_workflow_id
    FROM FD.WORKFLOW_EXECUTION
    WHERE execution_status ='Running' 
    )
) we INNER JOIN FD.PROJECT p on we.project_id = p.PROJECT_ID
  INNER JOIN FD.PROJECT_WORKFLOW pw on we.project_workflow_id = pw.project_workflow_id 
  INNER JOIN FD.WORKFLOW w on pw.workflow_id = w.workflow_id
  INNER JOIN FD.ENVIRONMENT env on we.environment_id = env.environment_id
  INNER JOIN FD.INSTANCE ins on we.instance_id = ins.instance_id 
  INNER JOIN FD.ENVIRONMENT_INSTANCE env_inst on env_inst.instance_id = ins.instance_id and env_inst.environment_id = env.environment_id
  LEFT OUTER JOIN FD.ENVIRONMENT last_env on we.last_exec_environment_id = last_env.environment_id
  LEFT OUTER JOIN FD.INSTANCE last_ins on we.last_exec_instance_id = last_ins.instance_id
  INNER JOIN FD.PROJECT_VERSION pv on we.project_version_id = pv.project_version_id 
  INNER JOIN FD.FOLDER f on p.folder_id = f.folder_id 
where execution_status = 'Running'
       and w.workflow_type in ('BUILD', 'DEPLOY', 'TEST', 'UTILITY');

CREATE OR REPLACE VIEW FD.VPARENTFLDR (FOLDER_ID) AS 
WITH RECURSIVE FOLDER  as (
    select f.FOLDER_ID
     from FD.FOLDER f
     UNION ALL
     SELECT f2.FOLDER_ID
     FROM FD.FOLDER f2
    INNER JOIN FOLDER efolder 
      ON efolder.FOLDER_ID = f2.PARENT_FOLDER_ID
)
SELECT * FROM FOLDER;

CREATE or replace VIEW FD.VPARENTWKFLW as
WITH RECURSIVE WKFLW  as (
    select we.WORKFLOW_EXECUTION_ID 
     from FD.WORKFLOW_EXECUTION we
     UNION ALL
     SELECT e.WORKFLOW_EXECUTION_ID
     FROM FD.WORKFLOW_EXECUTION e
    INNER JOIN WKFLW ewkflw 
      ON ewkflw.WORKFLOW_EXECUTION_ID = e.PARENT_WORKFLOW_EXECUTION_ID
)
SELECT * FROM WKFLW;
  
  CREATE OR REPLACE VIEW FD.VACTVPROJWFULLPATH (PROJECT_ID, FOLDER_ID, PROJECT_NAME, PARTIAL_DEPLOYMENTS, 
DEPLOY_PRIORITY, PROJECT_TYPE, FULL_PATH) AS 
select p.PROJECT_ID, p.FOLDER_ID, p.PROJECT_NAME, p.PARTIAL_DEPLOYMENTS, p.DEPLOY_PRIORITY, p.PROJECT_TYPE, fp.full_path
from FD.PROJECT P, 
(with recursive folders (project_id, folder_id, parent_folder_id, folder_name, lvl) as (
  select p.project_id, f.folder_id, f.parent_folder_id, f.folder_name, 0 lvl
  from FD.FOLDER f, FD.PROJECT p
  where f.folder_id = p.folder_id and p.IS_ACTIVE='Y'
  union all
  select p2. project_id, f2.folder_id, f2.parent_folder_id, f2.folder_name, f3.lvl + 1
  from folders f3, fd.folder f2, fd.project p2
  where f3.parent_folder_id = f2.folder_id and p2.project_id = f3.project_id)
select folders.project_id, string_agg(folders.folder_name, '/' order by lvl desc) as full_path from folders
group by folders.project_id) fp where p.IS_ACTIVE='Y' and p.project_id = fp.project_id;

CREATE OR REPLACE VIEW FD.VFOLDERHIERARCHY (FOLDER_ID,
PARENT_FOLDER_ID, FOLDER_NAME, DESCRIPTION, IS_APPLICATION, IS_ACTIVE
, CREATED_ON, CREATED_BY, UPDATED_ON, UPDATED_BY, VERSION_NUMBER,
START_FOLDER_ID) AS
WITH
  recursive FOLDERS (folder_id,parent_folder_id,folder_name,description,
  is_application,is_active,created_on,created_by,updated_on,updated_by,
  version_number,start_folder_id) AS
  (
    SELECT
      f.FOLDER_ID        AS folder_id,
      f.PARENT_FOLDER_ID AS parent_folder_id,
      f.FOLDER_NAME      AS folder_name,
      f.DESCRIPTION      AS description,
      f.IS_APPLICATION   AS is_application,
      f.IS_ACTIVE        AS is_active,
      f.CREATED_ON       AS created_on,
      f.CREATED_BY       AS created_by,
      f.UPDATED_ON       AS updated_on,
      f.UPDATED_BY       AS updated_by,
      f.VERSION_NUMBER   AS version_number,
      f.FOLDER_ID        AS start_folder_id
    FROM
      FD.FOLDER f
    UNION ALL
    SELECT
      f2.FOLDER_ID        AS folder_id,
      f2.PARENT_FOLDER_ID AS parent_folder_id,
      f2.FOLDER_NAME      AS folder_name,
      f2.DESCRIPTION      AS description,
      f2.IS_APPLICATION   AS is_application,
      f2.IS_ACTIVE        AS is_active,
      f2.CREATED_ON       AS created_on,
      f2.CREATED_BY       AS created_by,
      f2.UPDATED_ON       AS updated_on,
      f2.UPDATED_BY       AS updated_by,
      f2.VERSION_NUMBER   AS version_number,
      f3.start_folder_id  AS start_folder_id
    FROM
      FOLDERS f3
    JOIN FD.FOLDER f2 on f3.parent_folder_id = f2.FOLDER_ID
)
SELECT
  FOLDERS.folder_id        AS folder_id,
  FOLDERS.parent_folder_id AS parent_folder_id,
  FOLDERS.folder_name      AS folder_name,
  FOLDERS.description      AS description,
  FOLDERS.is_application   AS is_application,
  FOLDERS.is_active        AS is_active,
  FOLDERS.created_on       AS created_on,
  FOLDERS.created_by       AS created_by,
  FOLDERS.updated_on       AS updated_on,
  FOLDERS.updated_by       AS updated_by,
FOLDERS.version_number   AS version_number,
  FOLDERS.start_folder_id  AS start_folder_id
FROM
  FOLDERS;

CREATE OR REPLACE VIEW FD.VRPTENVDTSRCH AS
SELECT  
  WE.WORKFLOW_EXECUTION_ID,  
  P.PROJECT_ID,  
  P.FOLDER_ID,  
  P.PROJECT_NAME,  
  PV.PROJECT_VERSION_NAME,  
  PV.SCM_REVISION SCM_REVISION,  
  NULL PO_SCM_REVISION,  
  W.WORKFLOW_TYPE,  
  W.WORKFLOW_ID,  
  WV.WORKFLOW_VERSION,  
  E.ENVIRONMENT_NAME,  
  WE.ENVIRONMENT_ID,  
  I.INSTANCE_NAME,  
  WE.INSTANCE_ID,  
  WE.EXECUTION_STATUS,  
  WR.CREATED_ON REQUESTED_ON,  
  WR.CREATED_BY REQUESTED_BY,  
  WE.START_TIME,  
  WE.END_TIME,  
  WR.FLEX_FIELD_1,  
  WR.FLEX_FIELD_2,  
  WR.FLEX_FIELD_3,  
  WR.FLEX_FIELD_4,  
  WR.FLEX_FIELD_5,  
  WR.FLEX_FIELD_6,  
  WR.FLEX_FIELD_7,  
  WR.FLEX_FIELD_8,  
  WR.FLEX_FIELD_9,  
  WR.FLEX_FIELD_10,  
  PV.FLEX_FIELD_1 BUILD_FLEX_FIELD1,  
  PV.FLEX_FIELD_2 BUILD_FLEX_FIELD2,  
  PV.FLEX_FIELD_3 BUILD_FLEX_FIELD3,  
  PV.FLEX_FIELD_4 BUILD_FLEX_FIELD4,  
  PV.FLEX_FIELD_5 BUILD_FLEX_FIELD5,  
  PV.FLEX_FIELD_6 BUILD_FLEX_FIELD6,  
  PV.FLEX_FIELD_7 BUILD_FLEX_FIELD7,  
  PV.FLEX_FIELD_8 BUILD_FLEX_FIELD8,  
  PV.FLEX_FIELD_9 BUILD_FLEX_FIELD9,  
  PV.FLEX_FIELD_10 BUILD_FLEX_FIELD10,  
  PV.PACKAGE_NAME,  
  NULL OBJECT_PATH,  
  P.PARTIAL_DEPLOYMENTS,  
  PV.ALL_FILES_REQUESTED,  
  WR.REL_DEFINITION_ID,  
  WR.REL_SNAPSHOT_ID,  
  RD.REL_NAME,     
  RS.REL_SNAPSHOT,   
  WR.PIPELINE_STAGE_EXEC_ID as STAGE_EXEC_ID,  
  WR.WORKFLOW_REQUEST_ID,  
  WR.FOLDER_REQUEST_ID,  
  NULL PKG_STATUS, 
  (SELECT string_agg(ISSUE.ISSUE_NUMBER, ', ' ORDER BY ISSUE.ISSUE_NUMBER)  
   FROM FD.PROJECT_VERSION_ITS_ISSUE ISSUE WHERE ISSUE.PROJECT_VERSION_ID =  PV.PROJECT_VERSION_ID) as ITS_TICKET_IDS,  
  (SELECT string_agg(ISSUE_NUMBER, ', ' ORDER BY ISSUE_NUMBER) FROM FD.WORKFLOW_REQUEST_CMS_ISSUE WHERE WORKFLOW_REQUEST_ID=WR.WORKFLOW_REQUEST_ID) CMS_TICKET_IDS  
FROM   
  FD.WORKFLOW_EXECUTION WE,  
  FD.PROJECT P,  
  FD.PROJECT_VERSION PV,  
  FD.PROJECT_WORKFLOW PW,  
  FD.ENVIRONMENT E,  
  FD.INSTANCE I,  
  FD.WORKFLOW_VERSION WV,  
  FD.WORKFLOW W,  
  FD.WORKFLOW_REQUEST WR
  left outer join FD.REL_DEFINITION RD on WR.REL_DEFINITION_ID = RD.REL_DEFINITION_ID 
  left outer join FD.REL_SNAPSHOT RS  on WR.REL_SNAPSHOT_ID = RS.REL_SNAPSHOT_ID  
WHERE P.PROJECT_ID = WE.PROJECT_ID  
AND PW.PROJECT_WORKFLOW_ID = WE.PROJECT_WORKFLOW_ID  
AND E.ENVIRONMENT_ID = WE.ENVIRONMENT_ID  
AND I.INSTANCE_ID = WE.INSTANCE_ID  
AND PV.PROJECT_VERSION_ID = WE.PROJECT_VERSION_ID  
AND WV.WORKFLOW_VERSION_ID = WE.WORKFLOW_VERSION_ID  
AND W.WORKFLOW_ID = PW.WORKFLOW_ID  
AND WR.WORKFLOW_REQUEST_ID = WE.WORKFLOW_REQUEST_ID  
AND WE.PARENT_WORKFLOW_EXECUTION_ID IS NULL;

CREATE OR REPLACE VIEW FD.VRPTENVPROJSTAT as
SELECT
    we.workflow_execution_id,
    p.folder_id,
    p.project_id,
    p.project_name,
    pv.project_version_name,
    pv.scm_revision    scm_revision,
    pv.all_files_requested,
    e.environment_id,
    e.environment_name,
    i.instance_id,
    i.instance_name,
    we.execution_status,
    pw.project_workflow_type,
    we.start_time,
    we.end_time,
    wr.created_by      requested_by,
    wr.created_on      requested_on,
    wr.flex_field_1,
    wr.flex_field_2,
    wr.flex_field_3,
    wr.flex_field_4,
    wr.flex_field_5,
    wr.flex_field_6,
    wr.flex_field_7,
    wr.flex_field_8,
    wr.flex_field_9,
    wr.flex_field_10,
    pv.flex_field_1    build_flex_field1,
    pv.flex_field_2    build_flex_field2,
    pv.flex_field_3    build_flex_field3,
    pv.flex_field_4    build_flex_field4,
    pv.flex_field_5    build_flex_field5,
    pv.flex_field_6    build_flex_field6,
    pv.flex_field_7    build_flex_field7,
    pv.flex_field_8    build_flex_field8,
    pv.flex_field_9    build_flex_field9,
    pv.flex_field_10   build_flex_field10,
    NULL package_name,
    '' object_path,
    p.partial_deployments,
    f.folder_name,
    wr.rel_definition_id,
    rd.rel_name,
    rs.rel_snapshot,
    wr.workflow_request_id,
    wr.folder_request_id,
    wr.pipeline_stage_exec_id,
    (
        SELECT
            string_agg(ht.external_id, ', ' ORDER BY ht.external_id )
        FROM
            FD.HUMAN_TASK ht
        WHERE
            wr.workflow_request_id = ht.workflow_request_id
            OR wr.folder_request_id = ht.folder_request_id
    ) external_ticket,
    pv.project_version_id
FROM
    FD.WORKFLOW_EXECUTION we,
    FD.PROJECT p,
    FD.PROJECT_VERSION pv,
    FD.ENVIRONMENT e,
    FD.PROJECT_WORKFLOW pw,
    FD.INSTANCE i,
    FD.PROJECT_WF_CURRENT_STATUS pwcs, FD.WORKFLOW_REQUEST wr
    LEFT OUTER JOIN FD.REL_DEFINITION rd ON wr.rel_definition_id = rd.rel_definition_id
    LEFT OUTER JOIN FD.REL_SNAPSHOT rs ON wr.rel_snapshot_id = rs.rel_snapshot_id,
    FD.FOLDER f
WHERE
    p.project_id = we.project_id
    AND p.folder_id = f.folder_id
    AND pv.project_version_id = we.project_version_id
    AND e.environment_id = we.environment_id
    AND i.instance_id = we.instance_id
    AND pw.project_workflow_id = we.project_workflow_id
    AND p.partial_deployments = 'N'
    AND pw.project_workflow_type = 'DEPLOY'
    AND wr.workflow_request_id = we.workflow_request_id
    AND we.workflow_execution_id = pwcs.workflow_execution_id
UNION ALL
SELECT
    we.workflow_execution_id,
    p.folder_id,
    p.project_id,
    p.project_name,
    pv.project_version_name,
    pkgobj.scm_revision   scm_revision,
    pv.all_files_requested,
    e.environment_id,
    e.environment_name,
    i.instance_id,
    i.instance_name,
    we.execution_status,
    pw.project_workflow_type,
    we.start_time,
    we.end_time,
    wr.created_by         requested_by,
    wr.created_on         requested_on,
    wr.flex_field_1,
    wr.flex_field_2,
    wr.flex_field_3,
    wr.flex_field_4,
    wr.flex_field_5,
    wr.flex_field_6,
    wr.flex_field_7,
    wr.flex_field_8,
    wr.flex_field_9,
    wr.flex_field_10,
    pv.flex_field_1       build_flex_field1,
    pv.flex_field_2       build_flex_field2,
    pv.flex_field_3       build_flex_field3,
    pv.flex_field_4       build_flex_field4,
    pv.flex_field_5       build_flex_field5,
    pv.flex_field_6       build_flex_field6,
    pv.flex_field_7       build_flex_field7,
    pv.flex_field_8       build_flex_field8,
    pv.flex_field_9       build_flex_field9,
    pv.flex_field_10      build_flex_field10,
    pv.package_name       package_name,
    prjobj.object_path    object_path,
    p.partial_deployments,
    f.folder_name,
    wr.rel_definition_id,
    rd.rel_name,
    rs.rel_snapshot,
    wr.workflow_request_id,
    wr.folder_request_id,
    wr.pipeline_stage_exec_id,
    (
        SELECT
            string_agg(ht.external_id, ', ' ORDER BY ht.external_id )
        FROM
            FD.HUMAN_TASK ht
        WHERE
            wr.workflow_request_id = ht.workflow_request_id
            OR wr.folder_request_id = ht.folder_request_id
    ) external_ticket,
    pv.project_version_id
FROM
    FD.WORKFLOW_EXECUTION we,
    FD.PROJECT p,
    FD.PROJECT_VERSION pv,
    FD.ENVIRONMENT e,
    FD.PROJECT_WORKFLOW pw,
    FD.INSTANCE i,
    FD.PACKAGE_OBJ_CURRENT_STATUS pkjobjcs, FD.WORKFLOW_REQUEST wr
    LEFT OUTER JOIN FD.REL_DEFINITION rd ON wr.rel_definition_id = rd.rel_definition_id
    LEFT OUTER JOIN FD.REL_SNAPSHOT rs ON wr.rel_snapshot_id = rs.rel_snapshot_id,
    FD.PACKAGE_OBJECT pkgobj,
    FD.PROJECT_OBJECT prjobj,
    FD.FOLDER f
WHERE
    p.project_id = we.project_id
    AND p.folder_id = f.folder_id
    AND pv.project_version_id = we.project_version_id
    AND e.environment_id = we.environment_id
    AND i.instance_id = we.instance_id
    AND pw.project_workflow_id = we.project_workflow_id
    AND p.partial_deployments = 'Y'
    AND pw.project_workflow_type = 'DEPLOY'
    AND wr.workflow_request_id = we.workflow_request_id
    AND we.workflow_execution_id = pkjobjcs.workflow_execution_id
    AND p.project_id = pv.project_id
    AND pkgobj.project_object_id = pkjobjcs.project_object_id
    AND pv.project_version_id = pkgobj.project_version_id
    AND pkgobj.project_object_id = prjobj.project_object_id;
    