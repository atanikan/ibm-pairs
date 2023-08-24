INSERT INTO pairs.pairs_auth_group
(
id,
name,
query_limit_gb,
query_limit_run,
query_limit_tot,
query_limit_write
)
VALUES
(
nextval('pairs.pairs_auth_group_seq'),
'admin',
0,
0,
0,
0
);

insert into pairs.pairs_auth_user(
  id,
  login,
  name,
  password,
  admin,
  active,  
  status,
  grp
)
  select nextval( 'pairs.pairs_auth_user_seq'),
  'admin',
  'admin',
  MD5('r/chVszxwX1gXB4o'),
  'Y',
  'Y',
  10,
  id from pairs.pairs_auth_group order by id limit 1;  

