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

// Student type for student data
type Student record {
    int studentID?;
    string name;
    string email;
    string phone;
};

// RESTful service for student management
service /students on new http:Listener(8080) {

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
