___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Server-side Session Management",
  "description": "",
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
const encodeUriComponent = require('encodeUriComponent');

// temp
const JSON = require('JSON');


const firestoreCollection = data.firestoreCollection;
const firestoreDocument = sha256Sync(data.clientId == null ? (getEventData('client_id') || "1234ac116785") : data.clientId, {outputEncoding: 'hex'});
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

log("Collection is " + firestoreCollection + " and document is " + firestoreDocument);
log("Current timestamp is " + currentTimestamp);

let session = templateDataStorage.getItemCopy(firestoreDocument);
if (session) {
  
  log("Found session in storage");
  if ((currentTimestamp - session.last_timestamp) < (data.refreshTimeout * 1000) || (data.returnValue != "returnJson" && !data.activateRefresh && (currentTimestamp - session.last_timestamp) < (sessionLength * 60 * 1000))) {
    session.engagement_time_msec = currentTimestamp - session.session_id;
    session.data_mode = "storage";
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
  
  let session_doc = {};
  
  if (documents.length > 0) {
    
    log('Found a user ' + JSON.stringify(documents[0].data));

    let result = documents[0].data;
    oldTimestamp = result.last_timestamp;

    if (!result.last_timestamp || (currentTimestamp - result.last_timestamp) > (sessionLength * 60 * 1000)) {

      log("Starting a new session " + currentTimestamp);

      session_doc.session_id = currentTimestamp;
      session_doc.session_number = result.session_number + 1;
      session_doc.last_timestamp = currentTimestamp;
      
      return storeInFirestore(session_doc, "new");

    } else {

      log("Continuing an old session " + result.session_id);
      
      session_doc = result;
      session_doc.last_timestamp = currentTimestamp;

      return storeInFirestore(session_doc);
      
    }
    
  } else {
    
    log("not found");

    session_doc = {
      id: firestoreDocument,
      session_id: currentTimestamp, 
      last_timestamp: currentTimestamp,
      session_number: 1
    };
    
    return storeInFirestore(session_doc, "new");


//    return storeInFirestore(session_doc);

  }

    
}, (e) => {
  
  log(e);

});

function storeInFirestore(input, status) {
  
  if (data.activateEvents && (eventArray.length > 0 || eventArrayInclude.length == 0)) return input.session_id;
  
  input.engagement_time_msec = currentTimestamp - input.session_id;
  
  if (data.returnValue != "returnJson" && !data.activateRefresh) return input[data.returnValue];

  if ((currentTimestamp - oldTimestamp) > (data.refreshTimeout * 1000) || status == "new") {

    log("Diff is " + (currentTimestamp - oldTimestamp) + ". Writing to Firestore...");
    
    return Firestore.write(firestoreCollection + '/' + firestoreDocument, input, {
      projectId: data.gcpProject,
      merge: true,
    }).then((id) => {

      templateDataStorage.setItemCopy(firestoreDocument, input);

      input.data_mode = "firestore";

      return data.returnValue == "returnJson" ? input : input[data.returnValue];

      // return returnValue(session_doc);
    });

  } else {
    log("Diff is " + (currentTimestamp - oldTimestamp) + ". Not writing to Firestore...");
    input.data_mode = "no refresh";
    templateDataStorage.setItemCopy(firestoreDocument, input);
    
    log("input is " + JSON.stringify(input) + " \nreturn value is " + input[data.returnValue]);

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

Created on 10.2.2023, 11:44:35


