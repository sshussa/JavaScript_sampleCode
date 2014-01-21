<%@page import="org.apache.axis.tools.ant.foreach.ForeachTask"%>
<%@page import="org.apache.velocity.runtime.directive.Foreach"%>

<%
    /*

    Copyright (C) 2002 Fry Inc., All Rights Reserved.
    Purpose:
    The body of the product photo gallery (included by product.jsp).
    */
%>

<%@ page
	import="com.fry.ocp.catalog.*,
                 com.fry.ocp.util.StringUtil,
                 com.fry.wp.multisite.site.SiteManager,
                 com.fry.wp.multisite.util.i18n.I18NUtil,
                 com.fry.wp.multisite.utils.MultiSiteWebUtil,
                 com.fry.wp.multisite.utils.ProductVariantComparator,
                 com.fry.ocp.catalog.ProductVariant,
                 com.fry.wp.multisite.catalog.WhirlpoolProductAttributeGroupManager,
                 com.fry.wp.multisite.catalog.ProductFeature"
                %>
<%@ page import="com.fry.wp.multisite.util.ProductUtil"%>
<%@ page import="java.util.*"%>

<%@ taglib uri="/WEB-INF/ocp-site.tld" prefix="site"%>
<%@ taglib uri="/WEB-INF/ocp-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/ocp-user.tld" prefix="user"%>
<%@ taglib uri="/WEB-INF/ocp-i18n.tld" prefix="i18n"%>
<%@ taglib uri="/WEB-INF/ocp-cms.tld" prefix="cms"%>
<%@ taglib uri="/WEB-INF/ocp-logic.tld" prefix="logic"%>
<%@ taglib uri="/WEB-INF/ocp-cache.tld" prefix="cache"%>
<site:site id="currentSite" />
<i18n:bundle base="com.fry.wp.multisite.i18n.WPResourceBundle" locale='<%=SiteManager.getLocale(currentSite, request)%>' />

<% 
	/*
		Get product
	*/
	String productId = (request.getParameter("productId") == null) ? "" : request.getParameter("productId");

	Product product;
	if (!StringUtil.isEmpty(productId) && StringUtil.isLong(productId)) {
		try {
			product = ProductManager.getProduct(Long.parseLong(productId));
		} catch (Exception ex) {
			product = null;
			System.out.println(ex.getMessage());
		}
	} else {
		throw new javax.servlet.jsp.JspException("The productId was invalid. It's value was " + productId);
	}
	
	//Get Features list
    LinkedHashMap features;
	try {
		features = (LinkedHashMap)WhirlpoolProductAttributeGroupManager.findProductAttributeGroupsSorted(Long.parseLong(productId), "SF1", true);
	} catch (Exception e) {
		features = null;
		System.out.println(e.getMessage());
	}
	
	
	boolean hasMainFeature = false;
	ProductFeature mainFeature = null;
	List keyFeatures = new ArrayList();
	
	Iterator keySetFeatures = features.keySet().iterator();
	while(keySetFeatures.hasNext()){
		String keyIter = (String)keySetFeatures.next();
	
		SortedSet prodFeatures = (SortedSet) features.get(keyIter);
		boolean isWarranty = false;
		if("Warranty".equals(keyIter)) {
			isWarranty = true;
		}
		// Get the product feature list
		Iterator it = prodFeatures.iterator();
		List longDescList = new ArrayList();
		while (it.hasNext()) {
			ProductFeature pf = (ProductFeature)it.next();
			if(isWarranty){
				//warrantyContent = pf.getDisplayName();
			}
			if ("Benefit".equals(pf.getType()) && !StringUtil.isEmpty(pf.getValue())){
				if(!hasMainFeature){
					mainFeature = pf;
					hasMainFeature = true;
				}else{
					//longDescList.add(pf);
					keyFeatures.add(pf);
				}
			}
		}
	}

%>

<div id="key-features" class="section">
	<h2>Explore Key Features</h2>
	<table cellpadding=0 cellspacing=0 border=0 >
		<tr>
			<td valign="top" class="main-feature"><img src=""
				alt="ImgAltIfAvail" />
				<h4><%= mainFeature.getDisplayName() %></h4>
				<p><%= mainFeature.getValue() %></p></td>
			<td valign="top">
				<table id="add-features" cellpadding=0 cellspacing=0 border=0 class="features">
					<% for(int i = 0; i < keyFeatures.size(); i++){ 
						ProductFeature prodFeature= (ProductFeature) keyFeatures.get(i);
						// just to test with 5 key features
						if(i >= 4) break;
					%>

							<logic:if expression="<%=(i%2 == 0)%>">
							<tr>
							</logic:if>
								<td valign="top"><img src="http://placehold.it/185x125" alt="" />
								<h4><%=prodFeature.getDisplayName() %></h4>
								<p><%=prodFeature.getValue() %></p>
								</td>
							<logic:if expression="<%=(i%2 == 1)%>">
							</tr>
							</logic:if> 
					<%} %>
				</table>
			</td>
		</tr>
	</table>
</div>

