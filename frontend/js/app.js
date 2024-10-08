// API endpoints
const attendanceEndpoint = 'http://localhost:8080/attendance';
const studentEndpoint = 'http://localhost:8080/students';
const teacherEndpoint = 'http://localhost:8080/teachers';
const classEndpoint = 'http://localhost:8080/classes';
const notificationEndpoint = 'http://localhost:8080/notifications';
const reportEndpoint = 'http://localhost:8080/reports';

// Functions
// Define the showTab function
function showTab(tabName) {
    const tabs = document.getElementsByClassName('tab-content');
    for (let i = 0; i < tabs.length; i++) {
        tabs[i].classList.remove('active');
    }
    document.getElementById(tabName).classList.add('active');
    
    const tabButtons = document.getElementsByClassName('tab-button');
    for (let i = 0; i < tabButtons.length; i++) {
        tabButtons[i].classList.remove('active');
    }
    document.querySelector(`button[onclick="showTab('${tabName}')"]`).classList.add('active');
}

// Define the filterStudents function
function filterStudents() {
    const searchInput = document.getElementById('searchStudent');
    const filter = searchInput.value.toUpperCase();
    const table = document.getElementById('attendanceTable');
    const tr = table.getElementsByTagName('tr');
    
    for (let i = 0; i < tr.length; i++) {
        const td = tr[i].getElementsByTagName('td')[0];
        if (td) {
            const txtValue = td.textContent || td.innerText;
            if (txtValue.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = '';
            } else {
                tr[i].style.display = 'none';
            }
        }
    }
}

// Define the saveAttendance function
function saveAttendance() {
    const attendanceTable = document.getElementById('attendanceTable');
    const attendanceTableBody = attendanceTable.getElementsByTagName('tbody')[0];
    const attendanceRows = attendanceTableBody.getElementsByTagName('tr');
    
    const attendanceData = [];
    for (let i = 0; i < attendanceRows.length; i++) {
        const attendanceRow = attendanceRows[i];
        const studentId = attendanceRow.getElementsByTagName('td')[0].textContent;
        const status = attendanceRow.getElementsByTagName('td')[1].getElementsByTagName('select')[0].value;
        
        attendanceData.push({
            studentId: studentId,
            status: status
        });
    }
    
    axios.post('/attendance', attendanceData)
        .then(response => {
            if (response.status === 200) {
                console.log(response.data);
            } else {
                console.error("Error saving attendance: ", response.status);
            }
        })
        .catch(error => {
            console.error("Error saving attendance: ", error);
        });
}

// Define the createStudent function
document.getElementById('createStudentForm').addEventListener('submit', function(event) {
    event.preventDefault();
    
    const studentName = document.getElementById('studentNameInput').value;
    
    axios.post('/students', {
        name: studentName
    })
        .then(response => {
            if (response.status === 200) {
                console.log(response.data);
            } else {
                console.error("Error creating student: ", response.status);
            }
        })
        .catch(error => {
            console.error("Error creating student: ", error);
        });
});

// Define the createAttendance function
document.getElementById('createAttendanceForm').addEventListener('submit', function(event) {
    event.preventDefault();
    
    const studentId = document.getElementById('studentIdInput').value;
    const date = document.getElementById('dateInput').value;
    const status = document.getElementById('statusInput').value;
    
    axios .post('/attendance', {
        studentId: studentId,
        date: date,
        status: status
    })
        .then(response => {
            if (response.status === 200) {
                console.log(response.data);
            } else {
                console.error("Error creating attendance: ", response.status);
            }
        })
        .catch(error => {
            console.error("Error creating attendance: ", error);
        });
});

// Define the generateAttendanceReport function
function generateAttendanceReport() {
    axios.get('/attendance/report')
        .then(response => {
            const attendanceReport = document.getElementById('attendanceReport');
            attendanceReport.innerHTML = response.data;
        })
        .catch(error => {
            console.error(error);
        });
}

// Define the getStudentAttendance function
function getStudentAttendance() {
    axios.get('/attendance/student')
        .then(response => {
            const studentAttendanceTable = document.getElementById('studentAttendanceTable');
            const studentAttendanceTableBody = studentAttendanceTable.getElementsByTagName('tbody')[0];
            studentAttendanceTableBody.innerHTML = '';
            
            response.data.forEach(attendance => {
                const row = document.createElement('tr');
                const dateCell = document.createElement('td');
                const statusCell = document.createElement('td');
                
                dateCell.textContent = attendance.date;
                statusCell.textContent = attendance.status;
                
                row.appendChild(dateCell);
                row.appendChild(statusCell);
                
                studentAttendanceTableBody.appendChild(row);
            });
        })
        .catch(error => {
            console.error(error);
        });
}

// Define the getNotifications function
function getNotifications() {
    axios.get('/notifications')
        .then(response => {
            const notificationsList = document.getElementById('notificationsList');
            notificationsList.innerHTML = '';
            
            response.data.forEach(notification => {
                const notificationElement = document.createElement('div');
                notificationElement.textContent = notification.message;
                
                notificationsList.appendChild(notificationElement);
            });
        })
        .catch(error => {
            console.error(error);
        });
}

// Call the getStudentAttendance function
getStudentAttendance();

// Call the getNotifications function
getNotifications();

// Event listeners
if (document.getElementById('createStudentButton')) {
    document.getElementById('createStudentButton').addEventListener('click', createStudent);
}
if (document.getElementById('createAttendanceButton')) {
    document.getElementById('createAttendanceButton').addEventListener('click', createAttendance);
}
if (document.getElementById('saveAttendanceButton')) {
    document.getElementById('saveAttendanceButton').addEventListener('click', saveAttendance);
}