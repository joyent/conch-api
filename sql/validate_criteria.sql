-- Intel E5-2690 v4 spec: warn:93, crit:103
INSERT INTO device_validate_criteria ( component, condition, min, warn, crit )
       VALUES ( 'CPU', 'temp', 30, 60, 70 );

-- SAS_HDD for Toshiba AL14SEB120N flip at 65C.
INSERT INTO device_validate_criteria ( component, condition, min, warn, crit )
       VALUES ( 'SAS_HDD', 'temp', 25, 41, 51 );

-- SAS_SSD for HGST HUSMH8010BSS204 flip at 70C.
INSERT INTO device_validate_criteria ( component, condition, min, warn, crit )
       VALUES ( 'SAS_SSD', 'temp', 25, 41, 51 );
