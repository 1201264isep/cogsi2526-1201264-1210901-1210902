# Create the 'developers' group
create_developers_group:
  group.present:
    - name: developers

# Create the 'devuser' and add them to the 'developers' group
create_devuser:
  user.present:
    - name: devuser
    - groups:
      - developers
    - require:
      - group: create_developers_group

restrict_app_dir_access:
  file.directory:
    - name: /home/vagrant/app
    - user: devuser
    - group: developers
    - mode: '770'
    - require:
      - user: create_devuser

restrict_h2_data_dir_access:
  file.directory:
    - name: /home/vagrant/h2_data
    - user: devuser
    - group: developers
    - mode: '770'
    - makedirs: True
    - require:
      - user: create_devuser
