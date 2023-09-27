navigator.serviceWorker
    .register('/service-worker.js')
    .then(registration => {
      console.log('Service worker successfully registered.');
    })
    .catch(err => {
      console.error('Unable to register service worker.', err);
    });

const button = document.querySelector('button');

button.addEventListener('click', event => {

    Notification.requestPermission()
        .then(permission => {

            navigator.serviceWorker.ready.then(registration => {

                console.log('Service worker is active');

                registration.pushManager.subscribe({
                    userVisibleOnly: true,
                    applicationServerKey: 'some_public_key'
                }).then(pushSubscription => {
                    console.log('Received PushSubscription: ', JSON.stringify(pushSubscription));
                });
            });
        })
});