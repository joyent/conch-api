// filter out all but the first pass or failure for each device:component_type
var fs = require('fs');
var readline = require('readline');

var deviceMap = {};

var reader = readline.createInterface({
    input: process.stdin,
    output: process.stderr
});

reader.on('line', function (line) {
    var obj = JSON.parse(line);
    var deviceId = obj.device_id;
    var componentName = obj.validation_result.component_name;
    var validStatus = obj.validation_result.status;

    if (! ((deviceMap[deviceId] || {})[componentName] || {})[validStatus]) {
        if (! deviceMap[deviceId])
            deviceMap[deviceId] = {};
        if (! deviceMap[deviceId][componentName])
            deviceMap[deviceId][componentName] = {};

        deviceMap[deviceId][componentName][validStatus] = true;
        process.stdout.write(line + '\n');
    }

});
