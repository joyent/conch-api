var m = require('mithril');
var t = require("i18n4v");

module.exports = {
    passValidation :
        m("i.material-icons", { title : t("Device passes validation") }, "check"),

    failValidation :
        m("i.material-icons", { title : t("Device fails validation") }, "error_outline"),

    deviceReporting :
        m("i.material-icons", { title : t("Device reporting to Conch") }, "cloud_upload"),

    noReport :
        m("i.material-icons", { title : t("No reports collected from device") }, "help_outline"),

    findDeviceInRack :
        m("i.material-icons.md-18", "dns"),

    showRack :
        m("i.material-icons.md-18", "dns"),

    deviceProblems :
        m("i.material-icons.md-18", "report_problem"),

    deviceReport :
        m("i.material-icons.md-18", "description"),

};
