// find the first failure and first pass for each device:component_name
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
    var created = new Date(obj.created);
    // replace the string timestamp with the date object
    obj.created = created;

    var earliestFailure =
        ((deviceMap[deviceId] || {})[componentName] || {}).first_fail;
    var earliestSuccess =
        ((deviceMap[deviceId] || {})[componentName] || {}).first_pass;


    if (validStatus === 0) {
        if (! earliestFailure) {
            if (! deviceMap[deviceId])
                deviceMap[deviceId] = {};
            if (! deviceMap[deviceId][componentName])
                deviceMap[deviceId][componentName] = {};

            deviceMap[deviceId][componentName].first_fail = obj;
            deviceMap[deviceId][componentName].first_pass = null;
        }
        else if (earliestFailure.created > created) {
            deviceMap[deviceId][componentName].first_fail = obj;
        }
    }
    else if (validStatus === 1 &&
        earliestFailure &&
        earliestFailure.created < created)
    {
        if (! earliestSuccess) {
            // deviceMap is expected to be built because of earliestFailure
            // precondition
            deviceMap[deviceId][componentName].first_pass = obj;
        }
        else if (earliestSuccess.created > created) {
            deviceMap[deviceId][componentName].first_pass = obj;
        }
    }
}).on('close', function (){
    process.stdout.write( JSON.stringify(deviceMap) );
});

