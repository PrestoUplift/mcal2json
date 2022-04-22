//
// stuff goes here
//

import Foundation
import EventKit

// see https://github.com/feedback-assistant/reports/issues/189
extension EKParticipant {
    public var safeURL : URL? {
        perform(#selector(getter: EKParticipant.url))?.takeUnretainedValue() as? NSURL? as? URL
    }
}

struct Config {
    let startTime : Date
    let endTime : Date
}

struct Person : Codable {
    let name : String?
    let isCurrentUser : Bool
    let role : String
    let status : String
    let type : String
    let url : String

    init(fromEKParticipant participant: EKParticipant) {
        self.name = participant.name
        self.isCurrentUser = participant.isCurrentUser
        if let safeurl = participant.safeURL {
            self.url = safeurl.absoluteString
        } else {
            self.url = ""
        }

        switch participant.participantRole {
            case EKParticipantRole.chair:
                self.role = "Chair"

            case EKParticipantRole.nonParticipant:
                self.role = "NonParticipant"

            case EKParticipantRole.optional:
                self.role = "Optional"

            case EKParticipantRole.unknown:
                self.role = "Unknown"

            case EKParticipantRole.required:
                self.role = "Required"

            default:
                self.role = "unknown"

        }

        switch participant.participantStatus {
            case EKParticipantStatus.unknown:
                self.status = "Unknown"

            case EKParticipantStatus.pending:
                self.status = "Pending"

            case EKParticipantStatus.accepted:
                self.status = "Accepted"

            case EKParticipantStatus.completed:
                self.status = "Completed"

            case EKParticipantStatus.declined:
                self.status = "Declined"

            case EKParticipantStatus.delegated:
                self.status = "Delegated"

            case EKParticipantStatus.tentative:
                self.status = "Tentative"

            case EKParticipantStatus.inProcess:
                self.status = "InProcess"

            default:
                self.status = "unknown"
        }

        switch participant.participantType {
            case EKParticipantType.unknown:
                self.type = "Unknown"

            case EKParticipantType.person:
                self.type = "Person"

            case EKParticipantType.room:
                self.type = "Room"

            case EKParticipantType.resource:
                self.type = "Resource"

            case EKParticipantType.group:
                self.type = "Group"

            default:
                self.type = "unknown"
        }
    }
}

struct Event : Codable {
    let identifier : String
    let start : String
    let end : String
    let availability : String
    let allDay : Bool
    let organizer : Person?
    let status : String
    let location : String?
    let calendarIdentifier : String
    let title : String
    let creationDate : String?
    let lastModifiedDate : String?
    let timeZone : String?
    let url : String?
    let notes : String?
    let attendees : [Person]?
    let hasRecurrence : Bool

    init(fromEKEvent event: EKEvent) {
        self.identifier = event.eventIdentifier
        self.start = event.startDate.ISO8601Format()
        self.end = event.endDate.ISO8601Format()
        self.allDay = event.isAllDay
        self.location = event.location
        self.calendarIdentifier = event.calendar.calendarIdentifier
        self.title = event.title
        self.notes = event.notes
        self.hasRecurrence = event.hasRecurrenceRules

        if let participant = event.organizer {
            self.organizer = Person(fromEKParticipant: participant)
        } else {
            self.organizer = nil
        }

        if let creationDate = event.creationDate {
            self.creationDate = creationDate.ISO8601Format()
        } else {
            self.creationDate = nil
        }

        if let lastModifiedDate = event.lastModifiedDate {
            self.lastModifiedDate = lastModifiedDate.ISO8601Format()
        } else {
            self.lastModifiedDate = nil
        }

        if let timeZone = event.timeZone {
            self.timeZone = timeZone.identifier
        } else {
            self.timeZone = nil
        }

        if let url = event.url {
            self.url = url.absoluteString
        } else {
            self.url = nil
        }

        if let eventAttendees = event.attendees {
            var attendees = [Person]()
            for attende in eventAttendees {
                attendees.append(Person(fromEKParticipant: attende))
            }
            self.attendees = attendees
        } else {
            self.attendees = nil
        }

        switch event.availability {
            case EKEventAvailability.notSupported:
                self.availability = "NotSupported"

            case EKEventAvailability.busy:
                self.availability = "Busy"

            case EKEventAvailability.free:
                self.availability = "Free"

            case EKEventAvailability.tentative:
                self.availability = "Tentative"

            case EKEventAvailability.unavailable:
                self.availability = "Unavailable"

            default:
                self.availability = "unknown"
        }

        switch event.status {
            case EKEventStatus.canceled:
                self.status = "Canceled"

            case EKEventStatus.confirmed:
                self.status = "Confirmed"

            case EKEventStatus.none:
                self.status = "None"

            case EKEventStatus.tentative:
                self.status = "Tentative"

            default:
                self.status = "unknown"
        }

    }
}

struct Cal : Codable {
    let identifier : String
    let source : String

    init(fromEKCalendar calendar: EKCalendar) {
        self.identifier = calendar.calendarIdentifier
        self.source = calendar.source.sourceIdentifier
    }

}

struct CalName : Codable {
    let title : String
    var events : [Event]
    var calendars : [Cal]

    init(title: String) {
        self.title = title
        self.events = []
        self.calendars = []
    }
}

func getEKEventStore() -> EKEventStore {
    let store = EKEventStore()

    switch EKEventStore.authorizationStatus(for: .event) {
       case .notDetermined:
	       store.requestAccess(to: .event, completion:
		       {(granted: Bool, error: Error?) -> Void in
			       if granted {
				       print("access granted")
			       } else {
				       print("access denied")
			       }
	       })

    	case .denied:
       	print("access denied to calendars, try:\n\n",
	       	"   Preferences > Privacy > Calendars > [Your Terminal] > Check")
	       exit(1)

    	case .authorized:
       	break

    	default:
       	fputs("what happened there?", stderr)
    }

    return store
}

func getCalendarData(store: EKEventStore, startTime: Date, endTime: Date) -> Dictionary<String, CalName> {
    let calendars = store.calendars(for: .event)
    var data = Dictionary<String, CalName>()

    for calendar in calendars {

        let predicate = store.predicateForEvents(withStart: startTime as Date, end: endTime as Date, calendars: [calendar])

        let events = store.events(matching: predicate)

        if data[calendar.title] == nil {
            data[calendar.title] = CalName(title: calendar.title)
        }

        data[calendar.title]!.calendars.append(Cal(fromEKCalendar: calendar))
        for event in events {
            data[calendar.title]!.events.append(Event(fromEKEvent: event))
        }
    }
    return data
}

func argParse() -> Config {
    let USAGE = "Usage: mcal2json [integer offset of days from today]"

    let cal = Calendar.current
    let date = cal.startOfDay(for: Date())
    var startTime = date

    if (CommandLine.arguments.count > 1) {
        let cmd = CommandLine.arguments[1]
        switch cmd {
            case "help","h","-h","--help":
               print(USAGE)
               exit(0)
            default:
                if let dayOffset = Int(cmd) {
                    if let st = cal.date(byAdding: .day, value: dayOffset, to: date) {
                        startTime = st
                    } else {
                        print("Date out of range")
                        exit(1)
                    }
                } else {
                    print("Invalid number")
                    exit(1)
                }
        }
    }

    if let endTime = cal.date(bySettingHour: 23, minute: 59, second: 59, of: startTime) {
        let config = Config(startTime: startTime, endTime: endTime)
        return config
    } else {
        print("Couldn't generate config")
        exit(1)
    }
}

setbuf(stdout, nil);

let config = argParse()
let data = getCalendarData( store: getEKEventStore(),
                            startTime: config.startTime,
                            endTime: config.endTime)

do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let jsonData = try encoder.encode(data)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    print(jsonString)
} catch { print(error) }

