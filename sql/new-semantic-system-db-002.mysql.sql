-- MySQL Workbench Forward Engineering

CREATE DATABASE IF NOT EXISTS `mydb-test`;

USE DATABASE `mydb-test`;

DROP TABLE IF EXISTS `Item_has_Tag` ;
DROP TABLE IF EXISTS `Item_has_Date` ;


-- -----------------------------------------------------
-- Table `Item`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Item` ;

CREATE TABLE IF NOT EXISTS `Item` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Name` VARCHAR(45) NULL,
  `Description` VARCHAR(500) NULL,
  `Arrival` DATE NULL,
  `Expiry` DATE NULL,
  `Content` LONGBLOB NULL,
  `Created` DATE NULL,
  PRIMARY KEY (`Id`),
  UNIQUE INDEX `Id_UNIQUE` (`Id` ASC) VISIBLE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Tag`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Tag` ;

CREATE TABLE IF NOT EXISTS `Tag` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Name` VARCHAR(45) NULL,
  `Created` DATE NULL,
  PRIMARY KEY (`Id`),
  UNIQUE INDEX `Id_UNIQUE` (`Id` ASC) VISIBLE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Date`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Date` ;

CREATE TABLE IF NOT EXISTS `Date` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Date` DATE NULL,
  PRIMARY KEY (`Id`),
  UNIQUE INDEX `Id_UNIQUE` (`Id` ASC) VISIBLE
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Item_has_Date`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Item_has_Date` (
  `Item_Id` INT NOT NULL,
  `Date_Id` INT NOT NULL,
  PRIMARY KEY (`Date_Id`, `Item_Id`),
  INDEX `fk_Item_has_Date_Date1_idx` (`Date_Id` ASC) VISIBLE,
  INDEX `fk_Item_has_Date_Item1_idx` (`Item_Id` ASC) VISIBLE,
  CONSTRAINT `fk_Item_has_Date_Item1`
    FOREIGN KEY (`Item_Id`)
    REFERENCES `Item` (`Id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Item_has_Date_Date1`
    FOREIGN KEY (`Date_Id`)
    REFERENCES `Date` (`Id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Item_has_Tag`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Item_has_Tag` (
  `Item_Id` INT NOT NULL,
  `Tag_Id` INT NOT NULL,
  PRIMARY KEY (`Item_Id`, `Tag_Id`),
  INDEX `fk_Item_has_Tag_Tag1_idx` (`Tag_Id` ASC) VISIBLE,
  INDEX `fk_Item_has_Tag_Item1_idx` (`Item_Id` ASC) VISIBLE,
  CONSTRAINT `fk_Item_has_Tag_Item1`
    FOREIGN KEY (`Item_Id`)
    REFERENCES `Item` (`Id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Item_has_Tag_Tag1`
    FOREIGN KEY (`Tag_Id`)
    REFERENCES `Tag` (`Id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

