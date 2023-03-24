___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Server-side Session Management",
  "description": "This template helps to manage sessions for GA4 on the server instead of the client. Use Firestore to persist a session for an own-defined timeframe. Add your Session IDs, Counter and Engagement Time.",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "GROUP",
    "name": "firestore",
    "displayName": "Firestore Authorization",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "TEXT",
        "name": "gcpProject",
        "displayName": "ID of the GCP project",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "firestoreCollection",
        "displayName": "Name of the Collection in Firestore",
        "simpleValueType": true,
        "help": ""
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "sessions",
    "displayName": "Session Management",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "GROUP",
        "name": "migrateSessionData",
        "displayName": "Migrate sessions",
        "groupStyle": "NO_ZIPPY",
        "subParams": [
          {
            "type": "CHECKBOX",
            "name": "migrateSessionId",
            "checkboxText": "Take over existing session metrics for new users",
            "simpleValueType": true
          },
          {
            "type": "TEXT",
            "name": "sessionId",
            "displayName": "Variable with Session ID",
            "simpleValueType": true,
            "enablingConditions": [
              {
                "paramName": "migrateSessionId",
                "paramValue": true,
                "type": "EQUALS"
              }
            ]
          },
          {
            "type": "TEXT",
            "name": "sessionNumber",
            "displayName": "Variable with Session Number",
            "simpleValueType": true,
            "enablingConditions": [
              {
                "paramName": "migrateSessionId",
                "paramValue": true,
                "type": "EQUALS"
              }
            ]
          }
        ]
      },
      {
        "type": "TEXT",
        "name": "sessionLength",
        "displayName": "Time differenz between hits that will cause new session (in minutes)",
        "simpleValueType": true,
        "defaultValue": 30,
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          },
          {
            "type": "POSITIVE_NUMBER"
          }
        ]
      },
      {
        "type": "SELECT",
        "name": "clientId",
        "displayName": "Set the ID to be used for users or clients",
        "macrosInSelect": true,
        "selectItems": [],
        "simpleValueType": true,
        "notSetText": "Use client ID of the event"
      },
      {
        "type": "SELECT",
        "name": "sessionIdInput",
        "displayName": "Select the variabel which should be used as a session ID",
        "macrosInSelect": true,
        "selectItems": [
          {
            "value": "sessionIdInputTimestamp",
            "displayValue": "Use current timestamp"
          }
        ],
        "simpleValueType": true
      },
      {
        "type": "SELECT",
        "name": "returnValue",
        "displayName": "Specify which parameter should be returned",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "session_id",
            "displayValue": "Return only session_id"
          },
          {
            "value": "session_number",
            "displayValue": "Return only session_number"
          },
          {
            "value": "engagement_time_msec",
            "displayValue": "Return only engagement_time_msec"
          },
          {
            "value": "returnJson",
            "displayValue": "Return JSON with session_id, session_number and engagement_time_msec"
          },
          {
            "value": "data_mode",
            "displayValue": "Check if template storage is available"
          },
          {
            "value": "system_properties",
            "displayValue": "GA4 System Properties"
          },
          {
            "value": "session_engaged",
            "displayValue": "Session Engaged"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "session_id"
      },
      {
        "type": "CHECKBOX",
        "name": "activateRefresh",
        "checkboxText": "Active session refresh",
        "simpleValueType": true
      },
      {
        "type": "TEXT",
        "name": "refreshTimeout",
        "displayName": "Specify the interval after which a session should be refreshed in seconds",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "activateRefresh",
            "paramValue": true,
            "type": "EQUALS"
          }
        ],
        "defaultValue": 60
      },
      {
        "type": "CHECKBOX",
        "name": "activateEvents",
        "checkboxText": "Activate session generation only for specific events",
        "simpleValueType": true
      },
      {
        "type": "GROUP",
        "name": "addEvents",
        "displayName": "Include or exclude events from session generation",
        "groupStyle": "NO_ZIPPY",
        "subParams": [
          {
            "type": "SIMPLE_TABLE",
            "name": "includeEvents",
            "displayName": "Enter the names of the events that should generate a new session",
            "simpleTableColumns": [
              {
                "defaultValue": "",
                "displayName": "Event name",
                "name": "event_name_include",
                "type": "TEXT"
              }
            ],
            "newRowButtonText": "Add event"
          },
          {
            "type": "SIMPLE_TABLE",
            "name": "excludeEvents",
            "displayName": "Enter the names of the events that should not generate a new session",
            "simpleTableColumns": [
              {
                "defaultValue": "",
                "displayName": "Event name",
                "name": "event_name",
                "type": "TEXT"
              }
            ],
            "newRowButtonText": "Add event"
          }
        ],
        "enablingConditions": [
          {
            "paramName": "activateEvents",
            "paramValue": true,
            "type": "EQUALS"
          }
        ]
      },
      {
        "type": "TEXT",
        "name": "sessionEngaged",
        "displayName": "Time after which a second will count as engaged (in seconds)",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "returnValue",
            "paramValue": "session_engaged",
            "type": "EQUALS"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

// Vorlagencode hier eingeben.
const log = require('logToConsole');
const Firestore = require('Firestore');
const getTimestampMillis = require('getTimestampMillis');
const getEventData = require('getEventData');
const Object = require('Object');
const setResponseStatus = require('setResponseStatus');
const templateDataStorage = require('templateDataStorage');
const sha256Sync = require('sha256Sync');
const makeString = require('makeString');
const makeInteger = require('makeInteger');
const encodeUriComponent = require('encodeUriComponent');
const generateRandom = require('generateRandom');

// temp
const JSON = require('JSON');

const firestoreCollection = data.firestoreCollection;
const firestoreDocument = sha256Sync(data.clientId == null ? getEventData('client_id') : data.clientId, {outputEncoding: 'hex'});
if (!firestoreCollection||!firestoreDocument) return false;

const currentTimestamp = getTimestampMillis();
const sessionLength = data.sessionLength;
const excludeEvents = data.excludeEvents || [];
const includeEvents = data.includeEvents || [];
const eventName = getEventData('event_name');
const sessionId = getEventData('session_id');

if (sessionId) return sessionId;

let session_id, 
    session_number,
    oldTimestamp = currentTimestamp,
    eventArray = [],
    eventArrayInclude = [];

eventArray = (excludeEvents.length > 0) ? excludeEvents.filter(e => e.event_name == eventName) : [];
eventArrayInclude = (includeEvents.length > 0) ? includeEvents.filter(e => e.event_name == eventName) : [];

let session = templateDataStorage.getItemCopy(firestoreDocument);
if (session) {
  
  if ((currentTimestamp - session.last_timestamp) < (data.refreshTimeout * 1000) || (data.returnValue != "returnJson" && !data.activateRefresh && (currentTimestamp - session.last_timestamp) < (sessionLength * 60 * 1000))) {
    
    session.engagement_time_msec = currentTimestamp - session.last_timestamp;
    session.last_timestamp = currentTimestamp;
    templateDataStorage.setItemCopy(firestoreDocument, session);
    
    session.data_mode = "storage";
    
    let sessionEngaged = data.sessionEngaged * 1000 || null;
    session.session_engaged = (currentTimestamp - session.session_id*1000) > sessionEngaged ? 1 : null;
    
    return data.returnValue == "returnJson" ? session : makeString(session[data.returnValue]);
  }
}

if (data.returnValue == "data_mode" && session) {
  return "storage";
} else if (data.returnValue == "data_mode") {
  return "no storage"; 
}

const queries = [['id', '==', firestoreDocument]];

return Firestore.query(firestoreCollection, queries, {
  projectId: data.gcpProject,
}).then((documents) => {
  
  let session_doc = {}, 
      migrationId, 
      migrationNumber,
      systemProperties = {};
  
  if (data.migrateSessionId) {
    migrationId = data.sessionId;
    migrationNumber = data.sessionNumber;
  }

  if (documents.length > 0) {
    
    let result = documents[0].data;
    oldTimestamp = result.last_timestamp;

    if (!result.last_timestamp || (currentTimestamp - result.last_timestamp) > (sessionLength * 60 * 1000)) {

      session_doc.session_id = migrationId ? migrationId : (data.sessionIdInput == "sessionIdInputTimestamp" || !data.sessionIdInput || data.sessionIdInput === undefined || data.sessionIdInput === null) ? makeInteger(currentTimestamp / 1000) : data.sessionIdInput;
      session_doc.session_number = result.session_number + 1;
      session_doc.last_timestamp = currentTimestamp;
      session_doc.system_properties = {ss: 1};
      session_doc.engagement_time_msec = 0;

      return storeInFirestore(session_doc, "new");

    } else {
      
      let sessionEngaged = data.sessionEngaged * 1000 || null;

      session_doc = result;
      session_doc.last_timestamp = currentTimestamp;
      session_doc.system_properties = null;
      session_doc.engagement_time_msec = currentTimestamp - oldTimestamp;
      session_doc.session_engaged = (currentTimestamp - result.session_id*1000) > sessionEngaged ? 1 : null;

      return storeInFirestore(session_doc);
      
    }
    
  } else {
        
    session_doc = {
      id: firestoreDocument,
      session_id: migrationId ? migrationId : (data.sessionIdInput == "sessionIdInputTimestamp" || !data.sessionIdInput) ? makeInteger(currentTimestamp / 1000) : data.sessionIdInput, 
      last_timestamp: currentTimestamp,
      session_number: migrationNumber ? migrationNumber : 1,
      engagement_time_msec: 0,
      system_properties: {fv:1, ss: 1}
    };
    
    return storeInFirestore(session_doc, "new");
  }

    
}, (e) => {
  
  log(e);
  
  let session_doc_error = {
    session_id: null, 
    last_timestamp: currentTimestamp,
    session_number: null
  };
  
  return data.returnValue == "returnJson" ? session_doc_error : session_doc_error[data.returnValue];

});

function storeInFirestore(input, status) {
  
  if (data.activateEvents && (eventArray.length > 0 || eventArrayInclude.length == 0)) return input.session_id;
    
  if (data.returnValue != "returnJson" && !data.activateRefresh) return input[data.returnValue];

  if (((currentTimestamp - oldTimestamp) > (data.refreshTimeout * 1000) || status == "new") &&  (data.returnValue != "session_number" && data.returnValue != "engagement_time_msec" && data.returnValue != "system_properties" && data.returnValue != "session_engaged")) {
    
    return Firestore.write(firestoreCollection + '/' + firestoreDocument, input, {
      projectId: data.gcpProject,
      merge: true,
    }).then((id) => {

      templateDataStorage.setItemCopy(firestoreDocument, input);

      input.data_mode = "firestore";

      return data.returnValue == "returnJson" ? input : input[data.returnValue];

    }, (e) => {

      return data.returnValue == "returnJson" ? input : input[data.returnValue];

    });

  } else {

    input.data_mode = "no refresh";
    templateDataStorage.setItemCopy(firestoreDocument, input);
    
    return data.returnValue == "returnJson" ? input : input[data.returnValue];
  }
  
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_firestore",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedOptions",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "projectId"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "operation"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "read_write"
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "client_id"
              },
              {
                "type": 1,
                "string": "event_name"
              },
              {
                "type": 1,
                "string": "session_id"
              }
            ]
          }
        },
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 24.2.2023, 15:06:26


