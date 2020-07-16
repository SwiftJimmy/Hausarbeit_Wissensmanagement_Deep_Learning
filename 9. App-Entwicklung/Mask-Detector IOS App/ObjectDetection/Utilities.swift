import Foundation
/**
 Erweiterung der Date Klasse
 */
extension Date {
    
    /**
            Funktion gibt das Datum formatiert zurück
     */
    func getTimeAndDateFormatted(dateFormat: String) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "de_DE")
        // dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        dateFormatter.dateFormat = dateFormat
        
        return dateFormatter.string(from: self)
    }
    
    /**
           Funktion gibt den Namen des Wochentag zurück
    */
    func dayNameOfWeek() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
}
