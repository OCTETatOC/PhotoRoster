<%@page import="java.util.*,
				java.lang.Integer,
				blackboard.base.*,
				blackboard.data.*,
                blackboard.data.user.*,
				blackboard.data.course.*,
                blackboard.persist.*,
                blackboard.persist.user.*,
				blackboard.persist.course.*,
                blackboard.platform.*,
                blackboard.platform.persistence.*"
        errorPage="/error.jsp"                
%>
<SCRIPT LANGUAGE="JavaScript">
function imageError(theImage)
{	
theImage.src="https://idcard.oberlin.edu/feed/photo/profile.php?id=nophotos&b";
theImage.onerror = null;
}
</SCRIPT>
<%@ taglib uri="/bbData" prefix="bbData"%>                
<%@ taglib uri="/bbUI" prefix="bbUI"%>
<bbData:context id="ctx">
<%
/* This building block displays a student roster in every course and organization.
 * The student roster is only accessible through the control panel, thus only users with
 * access to the control panel can see it (such as instructors or teaching assitants)
 */
// create a persistence manager - needed for using loaders and persisters
BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();

//get the course id for the current course (that we are in) - this is the internal id e.g. "_2345_1"
Id courseId = bbPm.generateId(Course.DATA_TYPE, request.getParameter("course_id")); 
%>

<bbUI:docTemplate title="Student Roster">
<bbUI:coursePage courseId="<%=courseId%>">
<bbUI:breadcrumbBar handle="control_panel" isContent="false">
<!--<bbUI:breadcrumb>Student Roster</bbUI:breadcrumb> -->
</bbUI:breadcrumbBar>

<style type="text/css">
<!--
.style1 {
	color: saddlebrown;
	font-weight: bold;
}
#RoundedDiv {
	border-radius: 60px 60px 25px 25px;
	overflow:hidden;
	 }
-->
 </style>
 
<%
// makes sure that this option should be available for the course we are in
// Exco course along with any non-department, non-advising oganisations do not have access
//get the external course id - this is the Id you can search for in blackboard e.g. "DEPT-BIOL" or "200702-GEOL-110-01"
String id = ((Course)courseId.load()).getCourseId();
// is this a course which should have the roster? Roster is only made available for regular courses
boolean course;

try{
	// try converting the first 4 characters of the id to an integer (regular course id's start with the year they are taught)
	Integer temp = new Integer(id.substring(0,4));
	// make sure that the course is not EXCO
	if(id.substring(6).startsWith("-EXCO-")){
			course = false;
		}
		else{
			course = true;
		}
	}
catch(NumberFormatException e){
	course = false;
}
if(id.startsWith("P-")){
			course = true;
		}
// if the option should be available - make available only for departments, advising organizations and regular courses
if(id.startsWith("DEPT-") || id.startsWith("AD-") || id.startsWith("DSt-AmReads") || id.startsWith("SL-ODS") || id.startsWith ("OC-Fac_Coll") || id.startsWith("CON-") ||id.startsWith("CD-") ||course)
{ 
%>
		<%
		// create a Dbloader for users
		UserDbLoader loader = (UserDbLoader) bbPm.getLoader( UserDbLoader.TYPE );
		blackboard.base.BbList userlist = null;
		//load all users enrolled in the current course
		userlist = loader.loadByCourseId(courseId);
		
		
		
		// create a database loader for course membership objects
		CourseMembershipDbLoader cmLoader = (CourseMembershipDbLoader)bbPm.getLoader( CourseMembershipDbLoader.TYPE );
		// create a list to hold all students
		BbList students = new BbList();
		BbList instructor = new BbList();
		BbList TA = new BbList();
		
		// iterate thorugh the user list, keep only people enrolled with role Student/Participant
		BbList.Iterator userIter = userlist.getFilteringIterator();
		while(userIter.hasNext())
		{	//get the next user
			User thisUser = (User)userIter.next();
			
			// now use the CourseMembershipDBLoader to load the CourseMembership data for this user in this course.
			CourseMembership cmData = cmLoader.loadByCourseAndUserId(courseId, thisUser.getId());
			if (cmData.getRole() == cmData.getRole().STUDENT)
			{	//add the user to the list if he/she is a student
				 students.add(thisUser);
			}
			if (cmData.getRole() == cmData.getRole().INSTRUCTOR)
			{	//add the user to the list if he/she is a Instructor
				 instructor.add(thisUser);
			}
			if (cmData.getRole() == cmData.getRole().TEACHING_ASSISTANT)
			{	//add the user to the list if he/she is a TA
				 TA.add(thisUser);
			}
		} 
		
			// sort students by last name, first name
			GenericFieldComparator comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getFamilyName",User.class);
			comparator.appendSecondaryComparator(new GenericFieldComparator(BaseComparator.ASCENDING,"getGivenName",User.class));
			Collections.sort(students,comparator);
		%>

<div style="background-color:white; padding:20px; width=96%; max-width:960px;">	
<h2><%=id%></h2>
	
<table cellpadding="10">
<tr><td width="170"></td><td width="170"></td><td width="170"></td><td width="170"></td><td width="170"></td><td width="170"></td></tr>
<tr><td colspan="5"><span class="style1">INSTRUCTOR(S)</span></td></tr>
		<tr>
		<%
		// display the pictures of instructors
		BbList.Iterator instructorIter = instructor.getFilteringIterator();
		int i = 0;
		while(instructorIter.hasNext())
		{ 
			User thisUser = (User)instructorIter.next();
			i++;
			%>
			<td width="170"><img height="100px" src="https://octet1.csr.oberlin.edu/octet/Bb/Photos/expo/<%=thisUser.getUserName()%>/profileImage" onError="imageError(this)">
				<br/>
				<u><a href='mailto:<%=thisUser.getEmailAddress()%> '>
					<%=thisUser.getGivenName() %> &nbsp;<%=thisUser.getFamilyName() %>
					</a></u><br/>
				<%=thisUser.getTitle() %> <br/>
			</td>
			<%
			if(i%5==0)
			{
			%></tr><tr>  <%
			}
		}
		%>
			</tr>
			<tr><td colspan="5"><hr/><span class="style1">TEACHING ASST(s)</span></td></tr>
			<tr>
		<%
		// display the pictures of TAs
		BbList.Iterator TAIter = TA.getFilteringIterator();
		 i = 0;
		while(TAIter.hasNext())
		{ 
			User thisUserTA = (User)TAIter.next();
			i++;
			%>
			<td width="170"><div align="center">Teaching Asst.<br/><img height="100px" src="https://resdev.oberlin.edu/feed/photo/blank/<%=thisUserTA.getBatchUid()%>" onError="imageError(this)">			
				<br/>
				<u><a href='mailto:<%=thisUserTA.getEmailAddress()%> '>
					<%=thisUserTA.getGivenName() %> &nbsp;<%=thisUserTA.getFamilyName() %>
					</a></u><br/>
				<%=thisUserTA.getTitle() %> <br/>
			</div></td>
			<%
			if(i%5==0)
			{
			%></tr><tr><%
			}
		}
		%>
		
			</tr>
			<tr><td colspan="5"><hr/><span class="style1">STUDENTS</span></td></tr>
			<tr>
		<%
		// display the pictures of students
		BbList.Iterator studIter = students.getFilteringIterator();
		 i = 0;
		while(studIter.hasNext())
		{ 
			User thisUserStu = (User)studIter.next();
			i++;
			%>
			<td width="170"><div valign="top" align="center" id="RoundedDiv"><img height="120px" src="https://resdev.oberlin.edu/feed/photo/blank/<%=thisUserStu.getBatchUid()%>" onError="imageError(this)">
				<br/>
				<u><a href='mailto:<%=thisUserStu.getEmailAddress()%> '>
					<%=thisUserStu.getGivenName() %> &nbsp;<%=thisUserStu.getFamilyName() %>
					</a></u><br/>
				<%=thisUserStu.getTitle() %> <br/>
			</div></td>
			<%
			if(i%5==0)
			{
			%></tr><tr><%
			}
		}
		%>
		</table>
		<%


}
else // exco courses and general organizations do not have access to student photos
{
out.print("This option is not available for your course/organization at this time. Feel free to contact bbhelp@oberlin.edu if you believe this is a mistake.");
}
%>
</div>
</bbUI:coursePage>
</bbUI:docTemplate>
 </bbData:context>
 
