const message = document.getElementById('message')

navigator.serviceWorker
    .register(`${ window.location.pathname }service-worker.js`)
    .then(registration => {
      message.innerHTML += '<p>Service worker successfully registered</p>'
    })
    .catch(err => {
      message.innerHTML += `<p>Unable to register service worker - ${err}</p>`
    })

const request = document.getElementById('request')
const subscribe = document.getElementById('subscribe')

request.addEventListener('click', event => {
    Notification.requestPermission()
        .then(permission => {
            message.innerHTML += `<p>Permission ${permission}</p>`
        })
});

subscribe.addEventListener('click', event => {
    navigator.serviceWorker.ready
        .then(registration => {

        registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: 'BDntLA3k5K1tsrFOXXAuS_9Ey30jxy-R2CAosC2DOQnTs8LpQGxpTEx3AcPXinVYFFpJI6tT_RJC8pHgUsdbhOk'
        })
        .then(pushSubscription => {
            message.innerHTML += `<p>Received PushSubscription:</p>`
            message.innerHTML += `<p>${JSON.stringify(pushSubscription)}</p>`
        })
        .catch(err => {
            registration.pushManager.getSubscription().then(subscription => {
                if (subscription !== null) {
                    subscription
                      .unsubscribe()
                      .then(successful => {
                        message.innerHTML += '<p>Unsubscribed from existing subscription, please subscribe again</p>'
                      })
                      .catch(err => {
                        message.innerHTML += `<p>Failed to unsubscribe from existing subscription - ${err}</p>`
                      })
                } else {
                    message.innerHTML += '<p>No subscription found</p>'
                }
            })
        })
    })
})