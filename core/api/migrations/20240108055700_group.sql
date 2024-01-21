-- GROUP is a Reserved Keyword hence, Grp is used everywhere

CREATE TYPE GrpType AS ENUM (
  'FRIENDS',
  'TRIP',
  'HOME',
  'COUPLE',
  'OTHER'
);

CREATE TABLE Grp(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type GrpType NULL DEFAULT NULL,
  picture TEXT
);

CREATE TABLE GrpMembers(
  grp_id UUID NOT NULL REFERENCES Grp(id),
  uid UUID NOT NULL
);
