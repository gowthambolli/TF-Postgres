resource "null_resource" "db_remote_install" {
  connection {
    type     = "ssh"
    user     = "${var.user}"
    password = "${var.password}"
    host     = "${var.hostname}"
    timeout  = "${var.timeout}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install postgresql-server postgresql-contrib -yy",
      "sed -i 's/^local.*(md5|peer)/local all all trust/g' /var/lib/pgsql/data/pg_hba.conf",
      "sudo postgresql-setup initdb",
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql",
      "mkdir -p /tmp/scripts",
    ]
  }

  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp/scripts/"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /tmp/scripts/postgres/install",
      "psql -U postgres -d postgres -a -f CreateFlexDeploySchemas.sql",
      "cd && rm -rf /tmp/scripts"
    ]
  }
}
