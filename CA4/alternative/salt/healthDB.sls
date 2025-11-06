 check_h2_database_port:
  cmd.run:
    - name: "ss -ltn | grep ':9092'"
    - require:
      - cmd: start_h2_server
