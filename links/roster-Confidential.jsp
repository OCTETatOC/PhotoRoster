<%@page import="java.util.*,
				java.lang.Integer,
				blackboard.base.*,
				blackboard.data.*,
                blackboard.data.user.*,
				blackboard.data.course.*,
				blackboard.data.role.PortalRole,
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
/* This building block displays Photos of students in every course and organization.
 * The student roster is only accessible through the control panel, thus only users with
 * access to the control panel can see it (such as instructors, leaders, teaching assitants or assistants)
 */
// create a persistence manager - needed for using loaders and persisters
BbPersistenceManager bbPm = BbServiceManager.getPersistenceService().getDbPersistenceManager();

//get the course id for the current course (that we are in) - this is the internal id e.g. "_2345_1"
Id courseId = bbPm.generateId(Course.DATA_TYPE, request.getParameter("course_id")); 

%>
 <style type="text/css">
<!--
.style1 {
	color: #FF0000;
	font-weight: bold;
}
.style2{
	color: #280000 ;
	font-weight: 300;
	font-size: 80%;
	text-shadow: 1px 1px #DCDCDC;
	 }
#RoundedDiv{
    border-radius: 60px 60px 25px 25px; 
    overflow:hidden;
}	
-->
 </style>
 
<bbUI:docTemplate title="Confidential Photo Roster">
<bbUI:coursePage courseId="<%=courseId%>">
<bbUI:breadcrumbBar handle="control_panel" isContent="true">
 <bbUI:breadcrumb>Confidential Photo Roster</bbUI:breadcrumb>
</bbUI:breadcrumbBar>
<!-- <bbUI:titleBar>Confidential Photo Roster</bbUI:titleBar> -->
<%
// makes sure that this option should be available for the course we are in
// Exco course along with any non-department, non-advising oganizations do not have access
//get the external course id - this is the Id you can search for in blackboard e.g. "DEPT-BIOL" or "200702-GEOL-110-01"
String id = ((Course)courseId.load()).getCourseId();
// is this a course which should have the roster? Roster is only made available for regular courses
if(!id.startsWith("StuOrg") && !id.matches(".*EXCO.*")){
//if the list is modified, be sure to also change it in the Student Roster Public version
%>


			<%
		// create a Dbloader for users
		UserDbLoader loader = (UserDbLoader) bbPm.getLoader( UserDbLoader.TYPE );
		blackboard.base.BbList userlist = null;
		//load all users enrolled in the current course
		userlist = loader.loadByCourseId(courseId);
		
		
		
		// create a database loader for course membership objects
		CourseMembershipDbLoader cmLoader = (CourseMembershipDbLoader)bbPm.getLoader( CourseMembershipDbLoader.TYPE );
		// create a lists to hold various user with specific roles 
		BbList students = new BbList(); //all students
		
		// iterate thorugh the user list, place users in appropriate lists
		BbList.Iterator userIter = userlist.getFilteringIterator();
		while(userIter.hasNext())
		{	//get the next user
			User thisUser = (User)userIter.next();
			
			// now use the CourseMembershipDBLoader to load the CourseMembership data for this user in this course.
			CourseMembership cmData = cmLoader.loadByCourseAndUserId(courseId, thisUser.getId());
			if (cmData.getRole() == cmData.getRole().STUDENT)
			{	//add the user to the list of students if he/she is a student
				 students.add(thisUser);
			}
		
			
		} 
		
			// sort students by last name, first name
			GenericFieldComparator comparator = new GenericFieldComparator(BaseComparator.ASCENDING,"getFamilyName",User.class);
			comparator.appendSecondaryComparator(new GenericFieldComparator(BaseComparator.ASCENDING,"getGivenName",User.class));
			Collections.sort(students,comparator);
		
		

%>		
<!-- Conditions of use statement -->

<div style="background-color:white; padding:20px; width=96%"; max-width:960px;>
<span class="style1">Note:</span> <span class="style2"><i>The data here should be considered confidential. It is intended for use by instructors to get to know 
their students, contact them and, if needed, contact their class deans.  Please make every effort to guard the
confidentiality of your students by keeping any printed copy in your possession or storing it in a secure location at all times.
<br/>		
If you are interested in making the photos available to your students, go to your course menu and make the 'Student Roster' tool available.<br/></i></span>

<!-- display the pictures of students -->
		<span class='style2'>If you are off-campus, the photos will not display. To see them from off-campus you will need to use VPN to connect to our network before viewing this page. 
		Information on connecting via VPN can be found at <a href="http://citwiki.oberlin.edu/index.php/VPN#Where_do_I_get_VPN_software.3F" target="_blank"> http://citwiki.oberlin.edu/index.php/VPN </a></span> .<br/>
		<br/><b>Student/Participant members in this site:</b><br/>
	<table cellpadding="10" style="page-break-inside:avoid"><tr>
		
		<a href="/webapps/blackboard/execute/displayEmail?navItem=cp_send_email_all_students&course_id=<%= request.getParameter("course_id") %> ">email all students/participants in this site</a>
		<%
		BbList.Iterator studIter = students.getFilteringIterator();
		int s = 0;
		while(studIter.hasNext())
		{ 
			User thisUser = (User)studIter.next();
			s++;
			%>
			<td width="170px"><div align="center"><div id="RoundedDiv"> <img height="150" src="https://resdev.oberlin.edu/feed/photo/blank/<%=thisUser.getBatchUid()%>" onError="imageError(this)">
				</div><br>
				<%
				PortalRole userPortRole = thisUser.getPortalRole();
				String userPortalRole = "None"; // this is not displayed
				if(userPortRole!=null){
					userPortalRole = userPortRole.getRoleName();
				}
				%>
				<%=thisUser.getGivenName()%>&nbsp;<%=thisUser.getFamilyName()%><br/>
				<%=thisUser.getTitle()%><br/>
				<span class='style2'>
					<a href="mailto:<%=thisUser.getEmailAddress() %>"><%=thisUser.getEmailAddress() %></a>
				</span><br/>
             		 	<%=thisUser.getDepartment() %><br/>
           			<%=thisUser.getBusinessFax() %><br/>
				<span class="style2">
			 	<% 
			 	if (thisUser.getOtherName().length() > 1) {
		 			if (thisUser.getOtherName().substring(3).startsWith("Grier")) 
					{%>Class Dean: <br/> <a href="mailto:Brenda.Grier-Miller@oberlin.edu">Brenda.Grier-Miller@oberlin.edu</a>
		 			<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Davidson")) 
					{%>Class Dean: <br/> <a href="mailto:Kimberly.Jackson.Davidson@oberlin.edu">Kimberly.Jackson.Davidson@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Burgdorf")) 
					{%>Class Dean: <br/> <a href="mailto:Monique.Burgdorf@oberlin.edu">Monique.Burgdorf@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Donaldson")) 
					{%>Class Dean: <br/> <a href="mailto:Chris.Donaldson@oberlin.edu">Chris.Donaldson@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Flood")) 
					{%>Class Dean: <br/> <a href="mailto:Lori.Flood@oberlin.edu">Lori.Flood@oberlin.edu></a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Hayden")) 
					{%>Class Dean: <br/> <a href="mailto:Matthew.Hayden@oberlin.edu">Matthew.Hayden@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Salim")) 
					{%>Class Dean: <br/> <a href="mailto:Amy.Salim@oberlin.edu">Amy.Salim@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Kawaguchi")) 
					{%>Class Dean: <br/> <a href="mailto:Shozo.Kawaguchi@oberlin.edu">Shozo.Kawaguchi@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Hamdan")) 
					{%>Class Dean: <br/> <a href="mailto:Dana.Hamdan@oberlin.edu">Dana.Hamdan@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Brandt")) 
					{%>Class Dean: <br/> <a href="mailto:Anna.Brandt@oberlin.edu">Anna.Brandt@oberlin.edu</a>
					<% } else 
					if (thisUser.getOtherName().substring(3).startsWith("Myers")) 
					{%>Class Dean: <br/> <a href="mailto:tmyers@oberlin.edu">tmyers@oberlin.edu</a>
					<% }
				}
			 	%>
			 	</span>
				<br/>
				</div></td>
			<%
			if(s%5==0)
			{
				if(s%20==0){
					%></tr> </table>
					<span style="page-break-after:always"></span>
					<table cellpadding="10">
					<tr><%
				}else{
					%></tr><tr><%
				}
			}
		}
		%>
		</table>
		<%
} else {
	out.print("This option allows for potentially confidential student information to be seen. It is currently not available for your course/organization. <br/>Contact OCTET@oberlin.edu if you wish to make this available in your course/organization. <br/>If you are using this in an organization to view faculty and/or staff information, try activating and using the 'Photo Roster for Fac Staff' tool in your site. Information on how to do this can be found at <a href='http://octet1.csr.oberlin.edu/wp/BBhelp/' target='_blank'>http://octet1.csr.oberlin.edu/wp/BBhelp/</a> Search for 'photo roster' to find appropriate post. ");
}

%>
</div>
</bbUI:coursePage>
</bbUI:docTemplate>
 </bbData:context>
 
