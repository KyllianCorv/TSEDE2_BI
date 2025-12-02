use import;

create
    definer = root@`%` function CLEAN_NAME(str varchar(255)) returns varchar(255) deterministic
BEGIN
    -- Null direct si chaîne vide ou nulle
    IF str IS NULL OR TRIM(str) = '' THEN
        RETURN NULL;
    END IF;

    -- Traitement des accents
    SET str = UNACCENT(str);

    -- Nettoyage des formats
    SET str = REPLACE(str, '. ', '.');
    SET str = REPLACE(str, ' - ', '-');

    -- Trim final
    SET str = TRIM(str);

    -- Cas spécial : prénom/nom = '.'
    IF str = '.' THEN
        RETURN NULL;
    END IF;

    RETURN str;
END;


DELIMITER $$

CREATE FUNCTION format_ville_departement(nom VARCHAR(255)) RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
    DECLARE cleaned_nom VARCHAR(255);

    -- Nettoyage du nom : suppression des espaces et des guillemets
    set cleaned_nom = trim(nom);
    SET cleaned_nom = REPLACE(REPLACE(CLEAN_NAME(cleaned_nom), ' ', '-'), '"', '');
    SET cleaned_nom = replace(cleaned_nom,'\'','');
    SET cleaned_nom = REPLACE(cleaned_nom,'--', '-');
    RETURN cleaned_nom;
END$$

DELIMITER ;


create
    definer = root@`%` function format_prenom(nom varchar(255)) returns varchar(255) deterministic
BEGIN
    DECLARE part1 VARCHAR(255);
    DECLARE part2 VARCHAR(255);
    DECLARE cleaned_nom VARCHAR(255);

    -- Nettoyage du nom : suppression des espaces et des guillemets
    SET cleaned_nom = REPLACE(REPLACE(CLEAN_NAME(nom), ' ', '-'), '"', '');

    -- Si le nom ne contient pas de tiret, on renvoie le nom nettoyé
    IF cleaned_nom NOT LIKE '%-%' THEN
        RETURN cleaned_nom;
    END IF;

    -- Extraction des parties autour du tiret
    SET part1 = SUBSTRING_INDEX(cleaned_nom, '-', 1);
    SET part2 = SUBSTRING_INDEX(cleaned_nom, '-', -1);

    -- Retour du format "Initiale.Partie2"
    RETURN CONCAT(LEFT(part1, 1), '.', part2);
END;

CREATE
    DEFINER = root@`%`
    FUNCTION format_ville_departement(nom VARCHAR(255))
    RETURNS VARCHAR(255)
    DETERMINISTIC
BEGIN
    DECLARE cleaned_nom VARCHAR(255);
    DECLARE core VARCHAR(255);
    DECLARE suffix VARCHAR(255);
    DECLARE pos INT;

    SET cleaned_nom = TRIM(nom);

    -- Vérifie s’il y a une parenthèse finale du type " (xxx)"
    SET pos = LOCATE('(', cleaned_nom);

    IF pos > 0 AND RIGHT(cleaned_nom, 1) = ')' THEN
        -- Extraction du contenu des parenthèses
        SET suffix = SUBSTRING(cleaned_nom, pos + 1, CHAR_LENGTH(cleaned_nom) - pos - 1);
        -- Extraction de la partie avant les parenthèses
        SET core = TRIM(SUBSTRING(cleaned_nom, 1, pos - 1));

        -- Recompose : suffix + core
        -- On enlève les tirets potentiels inutiles autour
        SET cleaned_nom = CONCAT(TRIM(suffix), ' ', core);
    END IF;

    -- Nettoyage existant
    SET cleaned_nom = TRIM(cleaned_nom);
    SET cleaned_nom = REPLACE(REPLACE(CLEAN_NAME(cleaned_nom), ' ', '-'), '"', '');
    SET cleaned_nom = REPLACE(cleaned_nom, '''', '');
    SET cleaned_nom = REPLACE(cleaned_nom, '--', '-');

    RETURN cleaned_nom;
END;
create
    definer = root@`%` function remove_quotes_if_no_digits(input_value text) returns text deterministic
BEGIN
    -- Si la valeur contient un chiffre → return NULL
    IF input_value REGEXP '[0-9]' THEN
        RETURN NULL;
    END IF;

    -- Sinon on enlève les guillemets "
    RETURN REPLACE(input_value, '"', '');
END;

create
    definer = root@`%` function UNACCENT(str varchar(255)) returns varchar(255) deterministic
BEGIN
    SET str = LOWER(str);
    -- Accents français non convertis automatiquement
    SET str = REPLACE(str, 'é', 'e');
    SET str = REPLACE(str, 'è', 'e');
    SET str = REPLACE(str, 'ê', 'e');
    SET str = REPLACE(str, 'ë', 'e');

    SET str = REPLACE(str, 'à', 'a');
    SET str = REPLACE(str, 'â', 'a');
    SET str = REPLACE(str, 'ä', 'a');

    SET str = REPLACE(str, 'î', 'i');
    SET str = REPLACE(str, 'ï', 'i');

    SET str = REPLACE(str, 'ô', 'o');
    SET str = REPLACE(str, 'ö', 'o');

    SET str = REPLACE(str, 'ù', 'u');
    SET str = REPLACE(str, 'û', 'u');
    SET str = REPLACE(str, 'ü', 'u');

    SET str = REPLACE(str, 'ç', 'c');

    SET str = REPLACE(str, 'ñ', 'n');

    -- Ligatures françaises
    SET str = REPLACE(str, 'œ', 'oe');
    SET str = REPLACE(str, 'æ', 'ae');

    -- Mise en majuscule finale
    SET str = UPPER(str);

    RETURN str;

END;

create
    definer = root@`%` function validate_date(input_value text) returns date deterministic
BEGIN
    DECLARE parsed_date DATE;

    -- Vérifie d'abord le format strict : YYYY-MM-DD
    -- Année : 0001-9999 | Mois : 01-12 | Jour : 01-31
    IF input_value NOT REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' THEN
        RETURN NULL;
    END IF;

    -- Tente ensuite la conversion réelle (évite dates impossibles comme 2025-02-31)
    SET parsed_date = STR_TO_DATE(input_value, '%Y-%m-%d');

    IF parsed_date IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN parsed_date;
END;






create view v_Result_Elect_Circonscription as 
select `t`.`annee`                                                                                                                                                                                             AS `annee`,
       `t`.`tour`                                                                                                                                                                                              AS `tour`,
       `t`.`code_du_departement`                                                                                                                                                                               AS `code_du_departement`,
       `t`.`libelle_du_departement`                                                                                                                                                                            AS `libelle_du_departement`,
       `t`.`code_de_la_circonscription`                                                                                                                                                                        AS `code_de_la_circonscription`,
       `t`.`libelle_de_la_circonscription`                                                                                                                                                                     AS `libelle_de_la_circonscription`,
       `t`.`Inscrits`                                                                                                                                                                                          AS `Inscrits`,
       `t`.`Exprimes`                                                                                                                                                                                          AS `Exprimes`,
       `t`.`nuance`                                                                                                                                                                                            AS `nuance`,
       `t`.`nom`                                                                                                                                                                                               AS `nom`,
       `t`.`prenom`                                                                                                                                                                                            AS `prenom`,
       `t`.`sexe`                                                                                                                                                                                              AS `sexe`,
       `t`.`voix`                                                                                                                                                                                              AS `voix`,
       rank() over ( partition by `t`.`annee`,`t`.`tour`,`t`.`code_du_departement`,`t`.`libelle_du_departement`,`t`.`code_de_la_circonscription`,`t`.`libelle_de_la_circonscription` order by `t`.`voix` desc) AS `rang_elec`
from (select `v_unpivot_Elec_circonscription_unique`.`annee`                         AS `annee`,
             `v_unpivot_Elec_circonscription_unique`.`tour`                          AS `tour`,
             `v_unpivot_Elec_circonscription_unique`.`code_du_departement`           AS `code_du_departement`,
             `v_unpivot_Elec_circonscription_unique`.`libelle_du_departement`        AS `libelle_du_departement`,
             `v_unpivot_Elec_circonscription_unique`.`code_de_la_circonscription`    AS `code_de_la_circonscription`,
             `v_unpivot_Elec_circonscription_unique`.`libelle_de_la_circonscription` AS `libelle_de_la_circonscription`,
             sum(`v_unpivot_Elec_circonscription_unique`.`Inscrits`)                 AS `Inscrits`,
             sum(`v_unpivot_Elec_circonscription_unique`.`Exprimes`)                 AS `Exprimes`,
             `v_unpivot_Elec_circonscription_unique`.`nuance`                        AS `nuance`,
             `v_unpivot_Elec_circonscription_unique`.`nom`                           AS `nom`,
             `v_unpivot_Elec_circonscription_unique`.`prenom`                        AS `prenom`,
             `v_unpivot_Elec_circonscription_unique`.`sexe`                          AS `sexe`,
             sum(`v_unpivot_Elec_circonscription_unique`.`voix`)                     AS `voix`
      from `import`.`v_unpivot_Elec_circonscription_unique`
      group by `v_unpivot_Elec_circonscription_unique`.`annee`, `v_unpivot_Elec_circonscription_unique`.`tour`,
               `v_unpivot_Elec_circonscription_unique`.`code_du_departement`,
               `v_unpivot_Elec_circonscription_unique`.`libelle_du_departement`,
               `v_unpivot_Elec_circonscription_unique`.`code_de_la_circonscription`,
               `v_unpivot_Elec_circonscription_unique`.`libelle_de_la_circonscription`,
               `v_unpivot_Elec_circonscription_unique`.`nuance`, `v_unpivot_Elec_circonscription_unique`.`nom`,
               `v_unpivot_Elec_circonscription_unique`.`prenom`, `v_unpivot_Elec_circonscription_unique`.`sexe`) `t` ;




create view v_unpivot_Elec_circonscription as

select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance`                        AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom`                           AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom`                        AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe`                          AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix`                          AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance1`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom1`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom1`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe1`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix1`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom1` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance1`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom1`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom1`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe1`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix1`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom1` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance2`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom2`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom2`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe2`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix2`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom2` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance3`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom3`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom3`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe3`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix3`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom3` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance4`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom4`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom4`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe4`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix4`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom4` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance5`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom5`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom5`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe5`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix5`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom5` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance6`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom6`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom6`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe6`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix6`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom6` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance7`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom7`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom7`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe7`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix7`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom7` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance8`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom8`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom8`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe8`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix8`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom8` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance9`                       AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom9`                          AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom9`                       AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe9`                         AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix9`                         AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom9` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance10`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom10`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom10`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe10`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix10`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom10` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance11`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom11`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom11`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe11`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix11`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom11` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance12`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom12`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom12`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe12`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix12`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom12` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance13`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom13`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom13`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe13`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix13`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom13` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance14`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom14`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom14`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe14`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix14`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom14` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance15`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom15`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom15`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe15`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix15`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom15` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance16`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom16`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom16`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe16`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix16`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom16` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance17`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom17`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom17`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe17`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix17`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom17` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance18`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom18`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom18`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe18`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix18`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom18` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance19`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom19`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom19`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe19`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix19`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom19` <> ''
union all
select `import`.`Elec_circonscription_0_20`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_0_20`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_0_20`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_0_20`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_0_20`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_0_20`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_0_20`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_0_20`.`Nuance20`                      AS `nuance`,
       `import`.`Elec_circonscription_0_20`.`Nom20`                         AS `nom`,
       `import`.`Elec_circonscription_0_20`.`Prenom20`                      AS `prenom`,
       `import`.`Elec_circonscription_0_20`.`Sexe20`                        AS `sexe`,
       `import`.`Elec_circonscription_0_20`.`Voix20`                        AS `voix`
from `import`.`Elec_circonscription_0_20`
where `import`.`Elec_circonscription_0_20`.`Nom20` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance21`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom21`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom21`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe21`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix21`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom21` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance22`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom22`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom22`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe22`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix22`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom22` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance23`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom23`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom23`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe23`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix23`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom23` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance24`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom24`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom24`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe24`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix24`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom24` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance25`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom25`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom25`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe25`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix25`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom25` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance26`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom26`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom26`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe26`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix26`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom26` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance27`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom27`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom27`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe27`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix27`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom27` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance28`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom28`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom28`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe28`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix28`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom28` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance29`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom29`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom29`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe29`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix29`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom29` <> ''
union all
select `import`.`Elec_circonscription_21_30`.`annee`                         AS `annee`,
       `import`.`Elec_circonscription_21_30`.`tour`                          AS `tour`,
       `import`.`Elec_circonscription_21_30`.`Code_du_departement`           AS `Code_du_departement`,
       `import`.`Elec_circonscription_21_30`.`libelle_du_departement`        AS `Libelle_du_departement`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_circonscription`    AS `Code_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`libelle_de_la_circonscription` AS `Libelle_de_la_circonscription`,
       `import`.`Elec_circonscription_21_30`.`Code_de_la_commune`            AS `Code_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Libelle_de_la_commune`         AS `Libelle_de_la_commune`,
       `import`.`Elec_circonscription_21_30`.`Inscrits`                      AS `Inscrits`,
       `import`.`Elec_circonscription_21_30`.`Exprimes`                      AS `Exprimes`,
       `import`.`Elec_circonscription_21_30`.`Nuance30`                      AS `nuance`,
       `import`.`Elec_circonscription_21_30`.`Nom30`                         AS `nom`,
       `import`.`Elec_circonscription_21_30`.`Prenom30`                      AS `prenom`,
       `import`.`Elec_circonscription_21_30`.`Sexe30`                        AS `sexe`,
       `import`.`Elec_circonscription_21_30`.`Voix30`                        AS `voix`
from `import`.`Elec_circonscription_21_30`
where `import`.`Elec_circonscription_21_30`.`Nom30` <> '';


create view v_unpivot_Elec_circonscription_unique as
select distinct `v_unpivot_Elec_circonscription`.`annee`                         AS `annee`,
                `v_unpivot_Elec_circonscription`.`tour`                          AS `tour`,
                `v_unpivot_Elec_circonscription`.`code_du_departement`           AS `code_du_departement`,
                `v_unpivot_Elec_circonscription`.`libelle_du_departement`        AS `libelle_du_departement`,
                `v_unpivot_Elec_circonscription`.`code_de_la_circonscription`    AS `code_de_la_circonscription`,
                `v_unpivot_Elec_circonscription`.`libelle_de_la_circonscription` AS `libelle_de_la_circonscription`,
                `v_unpivot_Elec_circonscription`.`code_de_la_commune`            AS `code_de_la_commune`,
                `v_unpivot_Elec_circonscription`.`libelle_de_la_commune`         AS `libelle_de_la_commune`,
                `v_unpivot_Elec_circonscription`.`Inscrits`                      AS `Inscrits`,
                `v_unpivot_Elec_circonscription`.`Exprimes`                      AS `Exprimes`,
                `v_unpivot_Elec_circonscription`.`nuance`                        AS `nuance`,
                `v_unpivot_Elec_circonscription`.`nom`                           AS `nom`,
                `v_unpivot_Elec_circonscription`.`prenom`                        AS `prenom`,
                `v_unpivot_Elec_circonscription`.`sexe`                          AS `sexe`,
                `v_unpivot_Elec_circonscription`.`voix`                          AS `voix`
from `import`.`v_unpivot_Elec_circonscription`;


create view v_unpivot_Election_Legis as 
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance`                 AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom`                    AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom`                 AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe`                   AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix`                   AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance1`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom1`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom1`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe1`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix1`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom1` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance2`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom2`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom2`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe2`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix2`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom2` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance3`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom3`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom3`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe3`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix3`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom3` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance4`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom4`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom4`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe4`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix4`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom4` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance5`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom5`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom5`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe5`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix5`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom5` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance6`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom6`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom6`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe6`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix6`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom6` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance7`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom7`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom7`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe7`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix7`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom7` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance8`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom8`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom8`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe8`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix8`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom8` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance9`                AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom9`                   AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom9`                AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe9`                  AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix9`                  AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom9` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance10`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom10`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom10`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe10`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix10`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom10` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance11`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom11`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom11`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe11`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix11`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom11` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance12`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom12`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom12`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe12`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix12`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom12` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance13`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom13`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom13`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe13`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix13`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom13` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance14`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom14`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom14`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe14`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix14`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom14` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance15`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom15`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom15`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe15`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix15`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom15` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance16`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom16`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom16`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe16`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix16`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom16` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance17`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom17`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom17`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe17`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix17`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom17` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance18`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom18`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom18`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe18`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix18`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom18` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance19`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom19`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom19`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe19`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix19`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom19` <> ''
union all
select `import`.`Elec_legislative_0_20`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_0_20`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_0_20`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_0_20`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_0_20`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_0_20`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_0_20`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_0_20`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_0_20`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_0_20`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_0_20`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_0_20`.`Nuance20`               AS `nuance`,
       `import`.`Elec_legislative_0_20`.`Nom20`                  AS `nom`,
       `import`.`Elec_legislative_0_20`.`Prenom20`               AS `prenom`,
       `import`.`Elec_legislative_0_20`.`Sexe20`                 AS `sexe`,
       `import`.`Elec_legislative_0_20`.`Voix20`                 AS `voix`
from `import`.`Elec_legislative_0_20`
where `import`.`Elec_legislative_0_20`.`Nom20` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance21`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom21`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom21`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe21`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix21`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom21` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance22`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom22`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom22`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe22`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix22`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom22` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance23`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom23`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom23`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe23`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix23`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom23` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance24`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom24`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom24`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe24`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix24`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom24` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance25`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom25`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom25`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe25`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix25`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom25` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance26`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom26`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom26`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe26`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix26`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom26` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance27`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom27`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom27`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe27`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix27`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom27` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance28`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom28`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom28`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe28`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix28`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom28` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance29`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom29`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom29`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe29`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix29`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom29` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance30`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom30`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom30`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe30`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix30`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom30` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance31`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom31`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom31`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe31`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix31`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom31` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance32`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom32`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom32`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe32`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix32`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom32` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance33`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom33`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom33`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe33`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix33`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom33` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance34`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom34`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom34`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe34`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix34`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom34` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance35`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom35`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom35`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe35`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix35`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom35` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance36`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom36`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom36`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe36`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix36`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom36` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance37`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom37`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom37`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe37`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix37`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom37` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance38`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom38`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom38`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe38`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix38`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom38` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance39`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom39`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom39`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe39`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix39`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom39` <> ''
union all
select `import`.`Elec_legislative_21_40`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_21_40`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_21_40`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_21_40`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_21_40`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_21_40`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_21_40`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_21_40`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_21_40`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_21_40`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_21_40`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_21_40`.`Nuance40`               AS `nuance`,
       `import`.`Elec_legislative_21_40`.`Nom40`                  AS `nom`,
       `import`.`Elec_legislative_21_40`.`Prenom40`               AS `prenom`,
       `import`.`Elec_legislative_21_40`.`Sexe40`                 AS `sexe`,
       `import`.`Elec_legislative_21_40`.`Voix40`                 AS `voix`
from `import`.`Elec_legislative_21_40`
where `import`.`Elec_legislative_21_40`.`Nom40` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance41`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom41`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom41`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe41`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix41`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom41` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance42`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom42`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom42`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe42`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix42`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom42` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance43`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom43`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom43`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe43`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix43`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom43` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance44`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom44`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom44`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe44`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix44`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom44` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance45`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom45`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom45`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe45`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix45`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom45` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance46`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom46`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom46`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe46`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix46`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom46` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance47`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom47`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom47`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe47`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix47`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom47` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance48`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom48`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom48`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe48`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix48`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom48` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance49`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom49`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom49`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe49`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix49`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom49` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance50`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom50`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom50`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe50`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix50`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom50` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance51`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom51`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom51`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe51`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix51`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom51` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance52`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom52`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom52`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe52`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix52`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom52` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance53`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom53`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom53`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe53`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix53`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom53` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance54`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom54`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom54`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe54`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix54`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom54` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance55`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom55`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom55`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe55`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix55`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom55` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance56`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom56`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom56`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe56`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix56`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom56` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance57`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom57`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom57`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe57`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix57`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom57` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance58`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom58`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom58`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe58`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix58`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom58` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance59`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom59`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom59`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe59`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix59`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom59` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance60`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom60`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom60`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe60`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix60`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom60` <> ''
union all
select `import`.`Elec_legislative_41_61`.`annee`                  AS `annee`,
       `import`.`Elec_legislative_41_61`.`tour`                   AS `tour`,
       `import`.`Elec_legislative_41_61`.`Code_du_departement`    AS `Code_du_departement`,
       `import`.`Elec_legislative_41_61`.`libelle_du_departement` AS `libelle_du_departement`,
       `import`.`Elec_legislative_41_61`.`Code_de_la_commune`     AS `Code_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Libelle_de_la_commune`  AS `Libelle_de_la_commune`,
       `import`.`Elec_legislative_41_61`.`Inscrits`               AS `inscrits`,
       `import`.`Elec_legislative_41_61`.`Votants`                AS `votants`,
       `import`.`Elec_legislative_41_61`.`Abstentions`            AS `abstentions`,
       `import`.`Elec_legislative_41_61`.`Exprimes`               AS `exprimes`,
       `import`.`Elec_legislative_41_61`.`Blancs`                 AS `blancs`,
       `import`.`Elec_legislative_41_61`.`Nuls`                   AS `nuls`,
       `import`.`Elec_legislative_41_61`.`Nuance61`               AS `nuance`,
       `import`.`Elec_legislative_41_61`.`Nom61`                  AS `nom`,
       `import`.`Elec_legislative_41_61`.`Prenom61`               AS `prenom`,
       `import`.`Elec_legislative_41_61`.`Sexe61`                 AS `sexe`,
       `import`.`Elec_legislative_41_61`.`Voix61`                 AS `voix`
from `import`.`Elec_legislative_41_61`
where `import`.`Elec_legislative_41_61`.`Nom61` <> '' ;
