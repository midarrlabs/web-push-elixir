navigator.serviceWorker
    .register('/service-worker.js')
    .then(registration => {
      console.log('Service worker successfully registered.');
    })
    .catch(err => {
      console.error('Unable to register service worker.', err);
    });

    document.addEventListener('DOMContentLoaded', event => {

      const button = document.querySelector('button');

      button.addEventListener('click', event => {

              Notification.requestPermission().then(permission => {

                navigator.serviceWorker.ready.then(registration => {

                  console.log('Service worker is active');

                    registration.showNotification('Notification Test', {
                        body: 'Some message',
                    });
                });
              })
      });

    });
