begin;
insert into user_account(name, email, password) values('conch','conch@conch.joyent.us','$2a$04$h963P26i4rTMaVogvA2U7ePcZTYm2o0gfSHyxaUCZSuthkpg47Zbi');
insert into user_workspace_role(user_id,workspace_id,role) values(
    (select id from user_account where name='conch' limit 1),
    (select id from workspace where name='GLOBAL' limit 1),
    'admin'
);

commit;
