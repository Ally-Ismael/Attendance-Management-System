import ballerina/io;
import ballerinax/mysql;
import ballerina/http;
import ballerina/sql;

// MySQL Database connection configuration
mysql:Client dbClient = check new (host = "localhost",
                                   port = 3306,
                                   database = ("attendance_management"),
                                   user = "root",
                                   password = "AsherSamwaka227");

// Function to test database connection 
public function main() returns error? {
    // Simple query to test the connection
    sql:ParameterizedQuery query = `SELECT 1`;
    
    // Execute the query
    stream<record{}, sql:Error?> resultStream = dbClient->query(query);

    io:println("Database connection test successful!");

    // Close the result stream (Optional)
    check resultStream.close();
}

// Define an HTTP listener on port 8080
listener http:Listener httpListener = new (8080);

// Student type for student data
type Student record {
    int studentID?;
    string name;
    string email;
    string phone;
};

// Teacher type for teacher data
type Teacher record {
    int teacher_id?;
    string name;
    string email;
};

// Attendance type for attendance records
type Attendance record {
    int attendance_id?;
    int student_id;
    int class_id;
    string date;
    string status; // "Present" or "Absent"
};

// Class type for class records
type Class record {
    int class_id?;
    string course_name;
    int? teacher_id;
};

// Notification type for notification records
type Notification record {
    int notification_id?;
    int student_id;
    string message;
    string sent_at;
};

// Report type for report records
type Report record {
    int report_id?;
    int class_id;
    string generated_at;
    string file_path;
};

// RESTful service for student management
service /students on httpListener {

    // Create a new student (C)
    resource function post createStudent(http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Student student = check requestBody.cloneWithType(Student);

        // Log the student data
        io:println("Creating student: ", student);

        // Define a SQL query with parameterized query
        sql:ParameterizedQuery query = `INSERT INTO Student (name, email, phone) VALUES (${student.name}, ${student.email}, ${student.phone})`;

        // Execute the query
        _ = check dbClient->execute(query);

        check caller->respond("Student created successfully.");
    }

    // Retrieve a student by name (R)
    resource function get [string name](http:Caller caller, http:Request req) returns error? {
        // Define a SQL query to retrieve the student by name
        sql:ParameterizedQuery query = `SELECT * FROM Student WHERE name = ${name}`;

        // Execute the query
        stream<Student, sql:Error?> resultStream = dbClient->query(query);

        // Retrieve the student data
        Student student = {studentID: 0, name: "", email: "", phone: ""};
        error? e = resultStream.forEach(function(Student studentRecord) {
            student = studentRecord;
        });

        // Close the result stream
        check resultStream.close();

        // Check if student data was found
        if (student.studentID == 0) {
            io:println("Student not found for name: ", name);
            check caller->respond(http:NOT_FOUND);
        } else {
            io:println("Retrieved student: ", student);
            check caller->respond(student);
        }
    }

    // Update a student's information by name (U)
    resource function put [string name](http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Student updatedStudent = check requestBody.cloneWithType(Student);

        // Define a SQL query to update the student information
        sql:ParameterizedQuery query = `UPDATE Student SET name = ${updatedStudent.name}, email = ${updatedStudent.email}, phone = ${updatedStudent.phone} WHERE name = ${name}`;

        // Execute the query
        _ = check dbClient->execute(query);

        check caller->respond("Student updated successfully.");
    }

    // Delete a student by name (D)
    resource function delete [string name](http:Caller caller, http:Request req) returns error? {
        // Define a SQL query to delete the student by name
        sql:ParameterizedQuery query = `DELETE FROM Student WHERE name = ${name}`;

        // Execute the query
        _ = check dbClient->execute(query);

        check caller->respond("Student deleted successfully.");
    }

    
    // Retrieve all students (R)
    resource function get getAllStudents(http:Caller caller, http:Request req) returns error? {
        // Define a SQL query to retrieve all students
        sql:ParameterizedQuery query = `SELECT studentID, name, email, phone FROM Student`;

        // Execute the query
        stream<Student, sql:Error?> resultStream = dbClient->query(query);

        // Collect all student data
        Student[] students = [];
        error? e = resultStream.forEach(function(Student studentRecord) {
            students.push(studentRecord);
        });

        // Close the result stream
        check resultStream.close();

        // Respond with the list of students
        check caller->respond(students);
    }
}

// RESTful service for teacher management
service /teachers on httpListener {
    // Create CRUD functions for Teachers

    // Create a new teacher
    resource function post createTeacher(http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Teacher teacher = check requestBody.cloneWithType(Teacher);
        sql:ParameterizedQuery query = `INSERT INTO Teacher (name, email) VALUES (${teacher.name}, ${teacher.email})`;
        _ = check dbClient->execute(query);
        check caller->respond("Teacher created successfully.");
    }

    // Retrieve a teacher by name
    resource function get [string name](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery query = `SELECT * FROM Teacher WHERE name = ${name}`;
        stream<Teacher, sql:Error?> resultStream = dbClient->query(query);
        Teacher teacher = {teacher_id: 0, name: "", email: ""};
        error? e = resultStream.forEach(function(Teacher teacherRecord) {
            teacher = teacherRecord;
        });
        check resultStream.close();
        if (teacher.teacher_id == 0) {
            check caller->respond(http:NOT_FOUND);
        } else {
            check caller->respond(teacher);
        }
    }

    // Update a teacher by name
    resource function put [string name](http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Teacher updatedTeacher = check requestBody.cloneWithType(Teacher);
        sql:ParameterizedQuery query = `UPDATE Teacher SET name = ${updatedTeacher.name}, email = ${updatedTeacher.email} WHERE name = ${name}`;
        _ = check dbClient->execute(query);
        check caller->respond("Teacher updated successfully.");
    }

    // Delete a teacher by name
    resource function delete [string name](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery query = `DELETE FROM Teacher WHERE name = ${name}`;
        _ = check dbClient->execute(query);
        check caller->respond("Teacher deleted successfully.");
    }
}

// RESTful service for class management
service /classes on httpListener {

// Create a new class (C)
resource function post createClass(http:Caller caller, http:Request req) returns error? {
    json requestBody = check req.getJsonPayload();
    Class classData = check requestBody.cloneWithType(Class);

    // Define the SQL query with parameterized placeholders
    sql:ParameterizedQuery query;

    // Check if teacher_id is provided and handle it appropriately
    if classData.teacher_id is () {
        query = `INSERT INTO Class (course_name) VALUES (${classData.course_name})`;
    } else {
        // Ensure teacher_id is an int before inserting
        int teacherId = check classData.teacher_id.ensureType(int);
        query = `INSERT INTO Class (course_name, teacher_id) VALUES (${classData.course_name}, ${teacherId})`;
    }

    // Execute the query
    _ = check dbClient->execute(query);

    check caller->respond("Class created successfully.");
}


    // Retrieve a class by course name (R)
    resource function get [string course_name](http:Caller caller, http:Request req) returns error? {
        // Define a SQL query to retrieve the class by course name
        sql:ParameterizedQuery query = `SELECT * FROM Class WHERE course_name = ${course_name}`;

        // Execute the query and get the result stream
        stream<Class, sql:Error?> resultStream = dbClient->query(query);

        // Retrieve the class data
        Class classData = {class_id: 0, course_name: "", teacher_id: ()};
        error? e = resultStream.forEach(function(Class classRecord) {
            classData = classRecord;
        });

        // Close the result stream
        check resultStream.close();

        // Check if class data was found
        if (classData.class_id == 0) {
            io:println("Class not found for course_name: ", course_name);
            check caller->respond(http:NOT_FOUND);
        } else {
            io:println("Retrieved class: ", classData);
            check caller->respond(classData);
        }
    }

    // Update a class's information by course name (U)
    resource function put [string course_name](http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Class updatedClass = check requestBody.cloneWithType(Class);

        // Define the SQL query to update the class information
        sql:ParameterizedQuery query;

        if updatedClass.teacher_id is () {
            query = `UPDATE Class SET course_name = ${updatedClass.course_name} WHERE course_name = ${course_name}`;
        } else {
            // Ensure teacher_id is an int before using it
            int teacherId = check updatedClass.teacher_id.ensureType(int);
            query = `UPDATE Class SET course_name = ${updatedClass.course_name}, teacher_id = ${teacherId} WHERE course_name = ${course_name}`;
        }

        // Execute the query
        _ = check dbClient->execute(query);

        check caller->respond("Class updated successfully.");
    }

    // Delete a class by course name (D)
    resource function delete [string course_name](http:Caller caller, http:Request req) returns error? {
        // Define the SQL query to delete the class by course name
        sql:ParameterizedQuery query = `DELETE FROM Class WHERE course_name = ${course_name}`;

        // Execute the query
        _ = check dbClient->execute(query);

        check caller->respond("Class deleted successfully.");
    }

    // Retrieve all classes (R)
    resource function get getAllClasses(http:Caller caller, http:Request req) returns error? {
        // Define a SQL query to retrieve all classes
        sql:ParameterizedQuery query = `SELECT class_id, course_name, teacher_id FROM Class`;

        // Execute the query and get the result stream
        stream<Class, sql:Error?> resultStream = dbClient->query(query);

        // Collect all class data
        Class[] classes = [];
        error? e = resultStream.forEach(function(Class classRecord) {
            classes.push(classRecord);
        });

        // Close the result stream
        check resultStream.close();

        // Respond with the list of classes
        check caller->respond(classes);
    }
}

// RESTful service for attendance management
service /attendance on httpListener {

    // Create a new attendance record (C)
    resource function post createAttendance(http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Attendance attendanceData = check requestBody.cloneWithType(Attendance);

        sql:ParameterizedQuery insertQuery = `INSERT INTO Attendance (student_id, class_id, date, status) 
                                              VALUES (${attendanceData.student_id}, ${attendanceData.class_id}, 
                                                      ${attendanceData.date}, ${attendanceData.status})`;

        // Execute the query and handle errors
        _ = check dbClient->execute(insertQuery);

        check caller->respond("Attendance record created successfully.");
    }

    // Retrieve an attendance record by student ID and class ID (R)
    resource function get [int student_id]/[int class_id](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery selectQuery = `SELECT * FROM Attendance 
                                              WHERE student_id = ${student_id} AND class_id = ${class_id}`;
        stream<Attendance, sql:Error?> resultStream = dbClient->query(selectQuery);

        Attendance attendanceData = {attendance_id: 0, date: "", class_id: 0, student_id: 0, status: ""};
        error? e = resultStream.forEach(function(Attendance attendanceRecord) {
            attendanceData = attendanceRecord;
        });

        check resultStream.close();

        if (attendanceData.attendance_id == 0) {
            io:println("Attendance not found for:", class_id);
            check caller->respond(http:NOT_FOUND);
        } else {
            io:println("Retrieved attendance: ", class_id);
            check caller->respond(attendanceData);
        }
    };

    // Update an attendance record by ID (U)
    resource function put [int attendance_id](http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Attendance updatedAttendance = check requestBody.cloneWithType(Attendance);

        sql:ParameterizedQuery updateQuery = `UPDATE Attendance SET student_id = ${updatedAttendance.student_id}, 
                                               class_id = ${updatedAttendance.class_id}, 
                                               date = ${updatedAttendance.date}, 
                                               status = ${updatedAttendance.status} 
                                               WHERE attendance_id = ${attendance_id}`;

        // Execute the query and handle errors
        _ = check dbClient->execute(updateQuery);
        check caller->respond("Attendance record updated successfully.");
    }

    // Delete an attendance record by ID (D)
    resource function delete [int attendance_id](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM Attendance WHERE attendance_id = ${attendance_id}`;

        // Execute the query and handle errors
        _ = check dbClient->execute(deleteQuery);
        check caller->respond("Attendance record deleted successfully.");
    }

    // Retrieve all attendance records (R)
    resource function get getAllAttendance(http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery selectAllQuery = `SELECT * FROM Attendance`;
        stream<Attendance, sql:Error?> resultStream = dbClient->query(selectAllQuery);

        Attendance[] attendanceRecords = [];
        error? e = resultStream.forEach(function(Attendance attendanceRecord) {
            attendanceRecords.push(attendanceRecord);
        });

        check resultStream.close();
        check caller->respond(attendanceRecords);
    }
}

// RESTful service for notification management
service /notifications on httpListener {
    // Create a new notification (C)
    resource function post createNotification(http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Notification notificationData = check requestBody.cloneWithType(Notification);

        sql:ParameterizedQuery insertQuery = `INSERT INTO Notification (student_id, message) 
                                              VALUES (${notificationData.student_id}, ${notificationData.message})`;

        // Execute the query and handle errors
        _ = check dbClient->execute(insertQuery);
        check caller->respond("Notification created successfully.");
    }

    // Retrieve a notification by ID (R)
    resource function get [int notification_id](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery selectQuery = `SELECT * FROM Notification 
                                              WHERE notification_id = ${notification_id}`;
        stream<Notification, sql:Error?> resultStream = dbClient->query(selectQuery);

        Notification notificationData = {notification_id: 0, student_id: 0, message: "", sent_at: ""};
        error? e = resultStream.forEach(function(Notification notificationRecord) {
            notificationData = notificationRecord;
        });

        check resultStream.close();

        if (notificationData.notification_id == 0) {
            io:println("Notification not found for:", notification_id);
            check caller->respond(http:NOT_FOUND);
        } else {
            io:println("Retrieved notification: ", notification_id);
            check caller->respond(notificationData);
        }
    }

    // Update a notification by ID (U)
    resource function put [int notification_id](http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Notification updatedNotification = check requestBody.cloneWithType(Notification);

        sql:ParameterizedQuery updateQuery = `UPDATE Notification SET student_id = ${updatedNotification.student_id}, 
                                               message = ${updatedNotification.message} 
                                               WHERE notification_id = ${notification_id}`;

        // Execute the query and handle errors
        _ = check dbClient->execute(updateQuery);
        check caller->respond("Notification updated successfully.");
    }

    // Delete a notification by ID (D)
    resource function delete [int notification_id](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM Notification WHERE notification_id = ${notification_id}`;

        // Execute the query and handle errors
        _ = check dbClient->execute(deleteQuery);
        check caller->respond("Notification deleted successfully.");
    }

    // Retrieve all notifications for a student (R)
    resource function get getAllNotifications(http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery selectAllQuery = `SELECT * FROM Notification}`;
        stream<Notification, sql:Error?> resultStream = dbClient->query(selectAllQuery);

        Notification[] notifications = [];
        error? e = resultStream.forEach(function(Notification notificationRecord) {
            notifications.push(notificationRecord);
        });

        check resultStream.close();
        check caller->respond(notifications);
    }
}

// RESTful service for report management
service /reports on httpListener{
    // Create a new report (C)
    resource function post createReport(http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Report reportData = check requestBody.cloneWithType(Report);

        sql:ParameterizedQuery insertQuery = `INSERT INTO Report (class_id, file_path) 
                                              VALUES (${reportData.class_id}, ${reportData.file_path})`;

        // Execute the query and handle errors
        _ = check dbClient->execute(insertQuery);
        check caller->respond("Report created successfully.");
    }

    // Retrieve a report by ID (R)
    resource function get [int report_id](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery selectQuery = `SELECT * FROM Report 
                                              WHERE report_id = ${report_id}`;
        stream<Report, sql:Error?> resultStream = dbClient->query(selectQuery);

        Report reportData = {report_id: 0, class_id: 0, generated_at: "", file_path: ""};
        error? e = resultStream.forEach(function(Report reportRecord) {
            reportData = reportRecord;
        });

        check resultStream.close();

        if (reportData.report_id == 0) {
            io:println("Report not found for:", report_id);
            check caller->respond(http:NOT_FOUND);
        } else {
            io:println("Retrieved report: ", report_id);
            check caller->respond(reportData);
        }
    }

    // Update a report by ID (U)
    resource function put [int report_id](http:Caller caller, http:Request req) returns error? {
        json requestBody = check req.getJsonPayload();
        Report updatedReport = check requestBody.cloneWithType(Report);

        sql:ParameterizedQuery updateQuery = `UPDATE Report SET class_id = ${updatedReport.class_id}, 
                                               file_path = ${updatedReport.file_path} 
                                               WHERE report_id = ${report_id}`;

        // Execute the query and handle errors
        _ = check dbClient->execute(updateQuery);
        check caller->respond("Report updated successfully.");
    }

    // Delete a report by ID (D)
    resource function delete [int report_id](http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM Report WHERE report_id = ${report_id}`;

        // Execute the query and handle errors
        _ = check dbClient->execute(deleteQuery);
        check caller->respond("Report deleted successfully.");
    }

    // Retrieve all reports for a class (R)
    resource function get getAllReports(http:Caller caller, http:Request req) returns error? {
        sql:ParameterizedQuery selectAllQuery = `SELECT * FROM Report WHERE`;
        stream<Report, sql:Error?> resultStream = dbClient->query(selectAllQuery);

        Report[] reports = [];
        error? e = resultStream.forEach(function(Report reportRecord) {
            reports.push(reportRecord);
        });

        check resultStream.close();
        check caller->respond(reports);
    }
}