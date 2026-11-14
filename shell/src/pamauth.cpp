#include "pamauth.h"
#include <QMetaObject>
#include <QProcessEnvironment>
#include <cstdlib>
#include <cstring>
#include <security/pam_appl.h>
#include <thread>
#include <unistd.h>
#include <pwd.h>

namespace {
int conv(int n, const struct pam_message **msg, struct pam_response **resp, void *data) {
    auto *pw = static_cast<const std::string *>(data);
    auto *r = static_cast<pam_response *>(calloc(n, sizeof(pam_response)));
    if (!r) return PAM_BUF_ERR;
    for (int i = 0; i < n; ++i) {
        if (msg[i]->msg_style == PAM_PROMPT_ECHO_OFF || msg[i]->msg_style == PAM_PROMPT_ECHO_ON)
            r[i].resp = strdup(pw->c_str());
    }
    *resp = r;
    return PAM_SUCCESS;
}
}  // namespace

PamAuth::PamAuth(QObject *parent) : QObject(parent) {
    const passwd *pw = getpwuid(getuid());
    m_user = pw ? QString::fromLocal8Bit(pw->pw_name) : qEnvironmentVariable("USER");
}

bool PamAuth::verifySync(const QString &user, const QString &password, const QString &service) {
    std::string pw = password.toUtf8().toStdString();
    const std::string u = user.toUtf8().toStdString();
    const std::string s = service.toUtf8().toStdString();
    pam_conv c{conv, &pw};
    pam_handle_t *h = nullptr;
    if (pam_start(s.c_str(), u.c_str(), &c, &h) != PAM_SUCCESS) return false;
    const bool ok = pam_authenticate(h, PAM_DISALLOW_NULL_AUTHTOK) == PAM_SUCCESS;
    pam_end(h, PAM_SUCCESS);
    std::fill(pw.begin(), pw.end(), '\0');
    return ok;
}

void PamAuth::verify(const QString &password) {
    const QString user = m_user;
    const QString service = qEnvironmentVariable("BC_PAM_SERVICE", "bc-lock");
    std::thread([this, user, password, service] {
        const bool ok = verifySync(user, password, service);
        QMetaObject::invokeMethod(this, [this, ok] { emit finished(ok); }, Qt::QueuedConnection);
    }).detach();
}
