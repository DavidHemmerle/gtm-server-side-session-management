# Variable Template for a server-side session management

To make the implementation of cross-domain, multi-platform and Measurement Protocol setups easier, this variable template helps to take care of the session management server-isde. 
It can be imported into your own container using the template feature of the server-side Google Tag Manager.

![Screeshot of the template for server-side session management](https://david-hemmerle.de/storage/app/media/uploaded-files/bildschirmfoto-2023-02-10-um-184059.png)

The template is composed of two settings areas: The access to the Firestore and the definition of the session modalities. 

<div class="alert alert-primary d-flex align-items-center" role="alert">
	  <svg xmlns="http://www.w3.org/2000/svg" class="bi bi-exclamation-triangle-fill flex-shrink-0 me-2" viewBox="0 0 16 16" role="img" aria-label="Warning:" style="width:48px;height:48px;">
    <path d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767L8.982 1.566zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5zm.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/>
  </svg>
  <div class="ms-3">
If the server-side container is running in a manual setup, it is necessary to extend the configuration to access the firestore. Instructions can be found <a href="https://developers.google.com/tag-platform/tag-manager/server-side/manual-setup-guide">here</a>. 
  </div>
</div>


## Selecting settings for a server-side session management.

1. First setting is the **Session length**. By default it is 30 minutes.
2. For session attribution, an **user identity** is required. Normally, the client ID can be used for this, which should already be included in the event.
3. In addition to the **Session ID**, it is also possible to record the **Session Counter** and the **Engagement Time** on the server side. The latter differs from the client-side engagement time, however, in that it only captures the difference between the session start and the time of the event, and not the active time on the page.
4. Specify the time window in which the session should be refreshed. This event also updates the firestore, i.e. performs a write operation. **It is therefore recommended to consider the possible number of events here to control costs.** If the variable is used for multiple parameters, it makes sense to **enable the refresh for only one**.
5. If not every event should reactivate a session, **certain event names can be included or excluded** in the last setting. 


## Provide the GA4 events with their own session parameters

In the next step, the parameters can now be added to the GA4 event (on the server). For each parameter, a version of the variable with the respective output value (`session_id`, `session_number` or `engagement_time_msec`) is created for this purpose.

In the server-side GTM container, add these variables to the GA4 tag:

![Screeshot of how the parameters `session_id`, `session_number` and `engagement_time_msec` are added to the GA4 tag on the server](https://david-hemmerle.de/storage/app/media/uploaded-files/bildschirmfoto-2023-02-10-um-190242.png)

With this change, the parameters, if they should exist in the original event, **will be overwritten** with the new server-side values.
