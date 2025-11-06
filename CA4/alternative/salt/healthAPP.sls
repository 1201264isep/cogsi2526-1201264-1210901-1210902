check_spring_app_health:
  http.query:
    - name: http://localhost:8080/actuator/health
    - status: 200
    - match: '"status":"UP"'
    - require:
      - cmd: start_spring_boot_app
