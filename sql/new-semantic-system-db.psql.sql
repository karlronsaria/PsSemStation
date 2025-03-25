DROP TABLE IF EXISTS item_has_tag;
DROP TABLE IF EXISTS item_has_datetag;

DROP TABLE IF EXISTS item;

CREATE TABLE IF NOT EXISTS item (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR(45) NULL,
    description VARCHAR(45) NULL,
    arrival DATE NULL,
    expiry DATE NULL,
    content BYTEA NULL,
    created DATE NULL
);

DROP TABLE IF EXISTS tag;

CREATE TABLE IF NOT EXISTS tag (
    id INT NOT NULL PRIMARY KEY,
    name VARCHAR(45) NULL,
    created DATE NULL
);

CREATE TABLE IF NOT EXISTS item_has_tag (
    itemid INT NOT NULL,
    tagid INT NOT NULL,
    CONSTRAINT item_has_tag_pk
        PRIMARY KEY (itemid, tagid),
    CONSTRAINT item_has_tag_fk_itemid
        FOREIGN KEY (itemid)
        REFERENCES item (id),
    CONSTRAINT item_has_tag_fk_tagid
        FOREIGN KEY (tagid)
        REFERENCES tag (id)
);

CREATE TABLE IF NOT EXISTS item_has_datetag (
    itemid INT NOT NULL,
    Datetag DATE NOT NULL,
    CONSTRAINT item_has_datetag_pk
        PRIMARY KEY (itemid, Datetag),
    CONSTRAINT item_has_datetag_fk
        FOREIGN KEY (itemid)
        REFERENCES item (id)
);

CREATE UNIQUE INDEX IF NOT EXISTS itemid_idx ON item (id ASC);
CREATE UNIQUE INDEX IF NOT EXISTS tagid_idx ON tag (id ASC);
CREATE UNIQUE INDEX IF NOT EXISTS item_has_tag_itemid_idx ON item_has_tag (itemid ASC);
CREATE UNIQUE INDEX IF NOT EXISTS item_has_tag_tagid_idx ON item_has_tag (tagid ASC);
CREATE UNIQUE INDEX IF NOT EXISTS item_has_datetag_itemid_idx ON item_has_datetag (itemid ASC);

