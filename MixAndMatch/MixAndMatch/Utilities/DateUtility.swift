//
//  DateUtility.swift
//  MyPocketSBUX
//
//  Created by takashi on 2015/03/28.
//  Copyright (c) 2015年 Takashi Ikeda. All rights reserved.
//

import UIKit

class DateUtility {
    
    class func isEqualDateComponent(date1 : NSDate, date2 : NSDate) -> Bool{
        
        // 日付部分が同一かどうか
        let unitFlags: NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.TimeZone]
        
        let compo1 = NSCalendar.currentCalendar().components(unitFlags, fromDate: date1)
        let compo2 = NSCalendar.currentCalendar().components(unitFlags, fromDate: date2)
        
        compo1.timeZone = NSTimeZone.systemTimeZone()
        compo2.timeZone = NSTimeZone.systemTimeZone()
        
        return compo1.year == compo2.year && compo1.month == compo2.month && compo1.day == compo2.day
    }
    
    private class func edgeOfDay(date : NSDate, edgeString : String) -> NSDate {
        let formatterSrc = NSDateFormatter()
        formatterSrc.dateFormat = "yyyyMMdd"
        let dateStringSrc = formatterSrc.stringFromDate(date)
        
        let formatterDst = NSDateFormatter()
        formatterDst.dateFormat = "yyyyMMddHHmmssSSS"
        
        return formatterDst.dateFromString("\(dateStringSrc)\(edgeString)")!
    }
    
    class func firstEdgeOfDay(date : NSDate) -> NSDate {
        return edgeOfDay(date, edgeString: "000000000")
    }
    
    class func lastEdgeOfDay(date : NSDate) -> NSDate {
        return edgeOfDay(date, edgeString: "235959999")
    }
    
    class func dateFromSqliteDateTimeString(dateString : String) -> NSDate? {
        // TとZが不要なので消す
        var dateStringInner = (dateString as NSString).stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "Z"))
        if let index = dateString.rangeOfString("T", options: NSStringCompareOptions.LiteralSearch, range: nil, locale: nil) {
            dateStringInner.replaceRange(index, with: " ")
        }
        
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let date = formatter.dateFromString(dateStringInner)
        
        return date
    }
    
    class func dateFromSqliteDateTimeString(jsonObject: NSDictionary, key: String) -> NSDate {
        return DateUtility.dateFromSqliteDateTimeString((jsonObject[key] as? NSString ?? "1970-01-01T00:00:00") as String) ?? NSDate(timeIntervalSince1970: 0)
    }
    
    class func dateFromSqliteDateString(dateString : String) -> NSDate? {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.dateFromString(dateString)
        
        return date
    }

    class func localDateString(date : NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.FullStyle;
        formatter.timeStyle = NSDateFormatterStyle.NoStyle
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        formatter.locale = NSLocale.currentLocale()
        let dateStringSrc = formatter.stringFromDate(date)
        
        return dateStringSrc
    }
    
    class func localTimeString(date : NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.NoStyle;
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        formatter.locale = NSLocale.currentLocale()
        let dateStringSrc = formatter.stringFromDate(date)
        
        return dateStringSrc
    }
    
    class func minimumDate() -> NSDate {
        return NSDate(timeIntervalSince1970: 0)
    }
    
    class func railsLocalDateString(date : NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        formatter.locale = NSLocale.currentLocale()
        let dateStringSrc = formatter.stringFromDate(date)
        
        return dateStringSrc
    }
    
    class func utcDateStringFromDate(date: NSDate) -> String {
        //let utcDate = NSDate(timeInterval: (NSTimeInterval)(-1 * NSTimeZone.defaultTimeZone().secondsFromGMTForDate(date)), sinceDate: date)
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let dateStringSrc = formatter.stringFromDate(date)
        
        return dateStringSrc
        
    }
}
