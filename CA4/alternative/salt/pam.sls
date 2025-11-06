
install_pam_libraries:
  pkg.installed:
    - pkgs:
      - libpam-pwquality
      - libpam-modules

configure_common_password_pam:
  file.prepend:
    - name: /etc/pam.d/common-password
    - text: 'password        requisite                       pam_pwquality.so retry=3 minlen=12 minclass=3 remember=5 reject_username'
    - require:
      - pkg: install_pam_libraries

configure_account_lockout:
  file.prepend:
    - name: /etc/pam.d/common-auth
    - text:
      - 'auth    required                        pam_tally2.so onerr=fail deny=5 unlock_time=600'
    - require:
      - pkg: install_pam_libraries   
