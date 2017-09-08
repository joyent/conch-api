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

    showRelay :
        m("i.material-icons.md-18", "router"),

    relayActive :
        m("i.material-icons", "router"),

    warning :
        m("i.material-icons", "warning"),

    nav:  {
        status :
            m("i.material-icons", "assessment"),
        racks :
            m("i.material-icons", "dns"),
        problems :
            m("i.material-icons", "report_problem"),
        devices :
            m("i.material-icons", "description"),
        relays :
            m("i.material-icons", "router"),
        logout :
            m("i.material-icons", "exit_to_app"),
        feedback :
            m("i.material-icons", "message"),
    }

};
