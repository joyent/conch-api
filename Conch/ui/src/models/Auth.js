import m from "mithril";

const Auth = {
    loginEmail: "",
    password: "",
    _loggedIn: false,
    requireLogin(next) {
        if (Auth._loggedIn) return next;
        m
            .request({
                method: "GET",
                url: "/me",
            })
            .then(_res => {
                Auth._loggedIn = true;
                return next;
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    throw e;
                }
            });
    },
    setLoginEmail(value) {
        Auth.loginEmail = value;
    },
    setPassword(value) {
        Auth.password = value;
    },
    login() {
        return m
            .request({
                method: "POST",
                url: "/login",
                data: { user: Auth.loginEmail, password: Auth.password },
            })
            .then(res => {
                Auth._loggedIn = true;
            });
    },
    logout() {
        return m.request({ method: "POST", url: "/logout" }).then(res => {
            Auth._loggedIn = false;
        });
    },
};

export default Auth;
