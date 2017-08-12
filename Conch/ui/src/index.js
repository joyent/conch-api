var m = require("mithril");

var Rack = require("./views/Rack");
var Layout = require("./views/Layout");
var Login = require("./views/Login");
var Problem = require("./views/Problem");
var Device = require("./views/Device");
var t = require('i18n4v');

var korean = require('./languages/ko.js');
var languages = {
    en: require('./languages/en.js'),
    ko: korean,
    'ko-KR': korean
};

t.selectLanguage(['en', 'ko', 'ko-KR'], function (err, lang) {
    t.translator.add(languages[lang] ? languages[lang] : languages.en);
});


m.route(document.body, "/", {
    "/": {
        render: function() {
            return m(Layout, { active : 0 },
              m(Rack.allRacks),
              m(Rack.makeSelection)
            );
        }
    },
    "/rack": {
        render: function() {
            return m(Layout, { active : 1 },
              m(Rack.allRacks),
              m(Rack.makeSelection)
            );
        }
    },
    "/rack/:id": {
        render: function(vnode) {
            return m(Layout, { active : 2 },
                m(Rack.allRacks),
                m(Rack.rackLayout, vnode.attrs)
            );
        }
    },
    "/problem": {
        render: function(vnode) {
            return m(Layout, { active : 1 },
                m(Problem.selectProblemDevice),
                m(Problem.makeSelection)
            );
        }
    },
    "/problem/:id": {
        render: function(vnode) {
            return m(Layout, { active : 2 },
                m(Problem.selectProblemDevice),
                m(Problem.showDevice, vnode.attrs)
            );
        }
    },
    "/device": {
        render: function(vnode) {
            return m(Layout, { active : 1 },
                m(Device.allDevices),
                m(Device.makeSelection)
            );
        }
    },
    "/device/:id": {
        render: function(vnode) {
            return m(Layout, { active : 2 },
                m(Device.allDevices),
                m(Device.deviceReport, vnode.attrs)
            );
        }
    },
    "/login": Login
});
