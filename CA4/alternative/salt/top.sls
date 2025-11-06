base:

  'db':
    - db
    - pam
    - configure_users
    - healthDB

  'app':
    - app
    - pam
    - configure_users
    - healthAPP
