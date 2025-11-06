
update_db_apt_cache:
  pkg.uptodate:
    - refresh: True

# Install necessary packages for the database
install_db_packages:
  pkg.installed:
    - pkgs:
      - openjdk-17-jdk
      - unzip
    - require:
      - pkg: update_db_apt_cache

install_h2_database:
  archive.extracted:
    - name: /opt/h2
    - source: http://www.h2database.com/h2-2019-10-14.zip
    - user: root
    - group: root
    - if_missing: /opt/h2/h2/bin/h2.jar 
    - skip_verify: True
    - require:
      - pkg: install_db_packages

start_h2_server:
  cmd.run:
    - name: "nohup java -cp /opt/h2/h2/bin/h2*.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -web -webAllowOthers -webPort 8082 -baseDir /home/vagrant/h2_data -ifNotExists > /dev/null 2>&1 &"
    - user: vagrant
    - unless: "netstat -tuln | grep ':9092'"
    - require:
      - archive: install_h2_database

# Configure the firewall (UFW)
install_ufw:
  pkg.installed:
    - name: ufw

configure_ufw_rules:
  cmd.run:
    - name: |
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow from 192.168.56.12 to any port 9092 proto tcp comment 'Allow app server'
        echo "y" | ufw enable
    - unless: "ufw status | grep '9092/tcp.*192.168.56.12.*ALLOW IN'"
    - require:                                                          
      - pkg: install_ufw
