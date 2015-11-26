<?php

$manual = include __DIR__ . '/manual.php';

// $output = __DIR__ . "/../data/map/0000.map";
$output = __DIR__ . "/../assets/js/mapdata.js";

// http://www.tosbase.com/game/world-map/
$content = file_get_contents(__DIR__ . '/../data/worldmap.txt');

$etc = [];
$etc['en-US'] = file_get_contents(__DIR__ . '/../data/ETC-en-US.tsv');
$etc['zh-TW'] = file_get_contents(__DIR__ . '/../data/ETC-zh-TW.tsv');

$pattern = '|<div id="map_(\d+)" style="height: 71px; width: 71px; text-align: center; position: absolute; left: (\d+)px; bottom: (\d+)px;"|';

preg_match_all($pattern, $content, $matches, PREG_SET_ORDER);

$map = [];

foreach ($matches as $data) {
    $map_id = intval($data[1]);
    $map[$map_id] = get_map_data_from_tosbase($map_id);
    $map[$map_id]["location"] = [ intval($data[3]) + 2, (intval($data[2]) + 1)  ];
    // $map[$map_id]['name']['zh-TW'] = $manual[$map_id]['zh-TW'];
    if (isset($manual[$map_id]['en-US'])) {
        $map[$map_id]['name']['en-US'] = $manual[$map_id]['en-US'];
    }
    $map[$map_id]['name']['zh-TW'] = translate($map[$map_id]['name']['en-US']);
    if (empty($map[$map_id]['name']['zh-TW']) && isset($manual[$map_id]['zh-TW'])) {
        $map[$map_id]['name']['zh-TW'] = $manual[$map_id]['zh-TW'];
    }
    $map[$map_id]['teleportor'] = isset($manual[$map_id]['teleportor']);
}

ksort($map);

//
// output
//
$data = "var MAPDATA = " . json_encode($map, JSON_UNESCAPED_UNICODE | JSON_NUMERIC_CHECK) . ";";

file_put_contents($output, $data);
// file_put_contents(__DIR__ . '/mapdata.inc.php', '<?php $maps = ' . var_export($map, true) . ';');

// var_dump([1001 => $map[1001], 1561 => $map[1561]]);

//
// function
//

function get_map_data_from_tosbase($map_id)
{
    $file_path = __DIR__ . "/../data/map/{$map_id}.map";

    if (file_exists($file_path)) {
        $data = file_get_contents($file_path);
    } else {
        $url = "http://www.tosbase.com/game/world-map/{$map_id}/";
        printf("getting data from {$url}\n");
        $data = file_get_contents($url);
        file_put_contents($file_path, $data);
    }

    $map = [];

    $pattern = [];
    $pattern['name'] = '|<div><h1>([^<]+)</h1></div>|';
    $pattern['level'] = '|Level:</b> (\d+)<br/>|';
    $pattern['connectedMap'] = '|<a href="game/world-map/([\d]+)/" style="font-weight: bold;">[^<]+</a> \(|';

    $map['name']['en-US'] = regex_one($pattern['name'], $data);
    $map['level'] = regex_one($pattern['level'], $data);
    $connectedMaps = regex_all($pattern['connectedMap'], $data);
    foreach ($connectedMaps as $mid) {
        $map['connectedMap'][$mid] = [0,0];
    }

    return $map;
}

function regex_one($pattern, $subject)
{
    preg_match($pattern, $subject, $match);

    // var_dump(['pattern' => $pattern, 'match' => $match]);

    return (isset($match[1])) ? $match[1] : null;
}

function regex_all($pattern, $subject)
{
    preg_match_all($pattern, $subject, $match);

    return (isset($match[1])) ? $match[1] : null;
}

function print_lang_key($map)
{
    $mapids = array_flip(array_keys($map));
    foreach ($mapids as $index => $tmp) {
        $mapids[$index] = ['zh-TW' => '', 'teleportor' => false];
    }

    var_export($mapids);
}

function find_etc_key($name)
{
    global $etc;

    $basic_pattern = "|ETC_([^\s]+)\s%s\r|is";

    $pattern = sprintf($basic_pattern, $name);

    return regex_one($pattern, $etc['en-US']);
}

function find_etc_value($key)
{
    global $etc;

    $basic_pattern = "|ETC_%s\s(.*?)\n|is";

    $pattern = sprintf($basic_pattern, $key);

    return regex_one($pattern, $etc['zh-TW']);
}

function translate($name)
{
    if ($key = find_etc_key($name)) {
        return find_etc_value($key);
    }

    return "";
}
