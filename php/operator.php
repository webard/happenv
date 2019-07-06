<?php
function is_fqdn($fqdn)
{
    return (preg_match("/^([a-z\d](-*[a-z\d])*)(\.([a-z\d](-*[a-z\d])*))*$/i", $fqdn) //valid chars check
        && preg_match("/^.{1,253}$/", $fqdn) //overall length check
        && preg_match("/^[^\.]{1,63}(\.[^\.]{1,63})*$/", $fqdn)); //length of each label
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

        $user = str_replace('.', '-', $domain);
        var_dump($user);

        exec('bash /usr/lib/happenv/action.sh create "' . $domain . '" "' . $phpVersion . '" "' . $user . '" "/var/www/' . $domain . '"', $output);

        return $output;
    },
    'enable' => function () {
        if (empty($_GET['domain']) || !is_fqdn($_GET['domain'])) {
            die('No or invalid domain');
        }
        $domain = $_GET['domain'];

        exec('bash /usr/lib/happenv/action.sh enable "' . $domain . '"', $output);

        return $output;
    },

    'disable' => function () {
        if (empty($_GET['domain']) || !is_fqdn($_GET['domain'])) {
            die('No or invalid domain');
        }
        $domain = $_GET['domain'];

        exec('bash /usr/lib/happenv/action.sh disable "' . $domain . '"', $output);

        return $output;
    }
];

if (empty($_GET['action']) || !isset($actions[$_GET['action']]) || !is_callable($actions[$_GET['action']])) {
    die('No or invalid action');
}

print_r($actions[$_GET['action']]());
