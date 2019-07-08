<?php
function is_fqdn($fqdn)
{
    return (preg_match("/^([a-z\d](-*[a-z\d])*)(\.([a-z\d](-*[a-z\d])*))*$/i", $fqdn) && preg_match("/^.{1,253}$/", $fqdn) && preg_match("/^[^\.]{1,63}(\.[^\.]{1,63})*$/", $fqdn));
}

$avaialblePhpVersions = [
    '7.2'
];

$actions = [
    'create' => function () use ($avaialblePhpVersions) {
        if (empty($_GET['domain']) || !is_fqdn($_GET['domain'])) {
            die('No or invalid domain');
        }
        $domain = $_GET['domain'];

        if (empty($_GET['phpver']) || !in_array($_GET['phpver'], $avaialblePhpVersions)) {
            die('No or invalid PHP version');
        }
        $phpVersion = $_GET['phpver'];

        //TODO: trim everything except a-zA-Z0-9\-
        $user = str_replace('.', '-', $domain);

        exec('bash /usr/lib/happenv/action.sh create "' . $domain . '" "' . $phpVersion . '" "' . $user . '" "/var/www/' . $domain . '"', $output);

        return $output;
    },
    'enable' => function () use ($avaialblePhpVersions) {
        if (empty($_GET['domain']) || !is_fqdn($_GET['domain'])) {
            die('No or invalid domain');
        }
        $domain = $_GET['domain'];

        if (empty($_GET['phpver']) || !in_array($_GET['phpver'], $avaialblePhpVersions)) {
            die('No or invalid PHP version');
        }
        $phpVersion = $_GET['phpver'];

        exec('bash /usr/lib/happenv/action.sh enable "' . $domain . '" "' . $phpVersion . '"', $output);

        return $output;
    },

    'disable' => function () use ($avaialblePhpVersions) {
        if (empty($_GET['domain']) || !is_fqdn($_GET['domain'])) {
            die('No or invalid domain');
        }
        $domain = $_GET['domain'];

        if (empty($_GET['phpver']) || !in_array($_GET['phpver'], $avaialblePhpVersions)) {
            die('No or invalid PHP version');
        }
        $phpVersion = $_GET['phpver'];

        exec('bash /usr/lib/happenv/action.sh disable "' . $domain . '" "' . $phpVersion . '"', $output);

        return $output;
    },

    'remove' => function () use ($avaialblePhpVersions) {
        if (empty($_GET['domain']) || !is_fqdn($_GET['domain'])) {
            die('No or invalid domain');
        }
        $domain = $_GET['domain'];

        //TODO: trim everything except a-zA-Z0-9\-
        $user = str_replace('.', '-', $domain);

        if (empty($_GET['phpver']) || !in_array($_GET['phpver'], $avaialblePhpVersions)) {
            die('No or invalid PHP version');
        }
        $phpVersion = $_GET['phpver'];

        exec('bash /usr/lib/happenv/action.sh remove "' . $domain . '" "' . $phpVersion . '" "' . $user . '" "/var/www/' . $domain . '"', $output);


        return $output;
    },
    'install' => '',
];

if (empty($_GET['action']) || !isset($actions[$_GET['action']]) || !is_callable($actions[$_GET['action']])) {
    die('No or invalid action');
}

$actions[$_GET['action']]();
