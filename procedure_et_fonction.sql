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

