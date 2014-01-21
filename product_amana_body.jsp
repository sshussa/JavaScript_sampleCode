<%@page import="org.apache.velocity.runtime.directive.Foreach"%>
<%@ page
	import="com.fry.ocp.catalog.*,
                 com.fry.ocp.cms.CMSManager,
                 com.fry.ocp.util.StringUtil,
                 com.fry.wp.multisite.site.SiteManager,
                 com.fry.wp.multisite.site.SiteUtil,
                 com.fry.wp.multisite.util.i18n.I18NUtil,
                 com.fry.wp.multisite.utils.MultiSiteWebUtil,
                 com.fry.wp.multisite.utils.ProductVariantComparator,
                 com.fry.wp.multisite.util.SEOUtil,
                 com.fry.wp.multisite.catalog.WhirlpoolProductAttributeGroupManager,
                 com.fry.wp.multisite.catalog.ProductFeature,
                 com.fry.wp.multisite.catalog.WhirlpoolProductManager, com.fry.wp.multisite.catalog.ProductImageUtil"%>
<%@ page import="com.fry.wp.multisite.util.ProductUtil"%>
<%@ page import="com.fry.wp.multisite.utils.CatalogUtils"%>
<%@ page import="java.util.*"%>
<%@ page import="com.fry.ocp.cms.Page"%>
<%@ page import="com.fry.ocp.cms.PageManager"%>
<%@ page import="com.fry.ocp.cms.Section"%>
<%
    /*

    Copyright (C) 2002 Fry Inc., All Rights Reserved.
    Purpose:
    The body of the product detail page (included by product.jsp).
    */
%>

<%@ taglib uri="/WEB-INF/ocp-site.tld" prefix="site"%>
<%@ taglib uri="/WEB-INF/ocp-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/ocp-user.tld" prefix="user"%>
<%@ taglib uri="/WEB-INF/ocp-i18n.tld" prefix="i18n"%>
<%@ taglib uri="/WEB-INF/ocp-cms.tld" prefix="cms"%>
<%@ taglib uri="/WEB-INF/ocp-logic.tld" prefix="logic"%>
<%@ taglib uri="/WEB-INF/ocp-cache.tld" prefix="cache"%>
<site:site id="currentSite" />
<i18n:bundle base="com.fry.wp.multisite.i18n.WPResourceBundle"
	locale='<%=SiteManager.getLocale(currentSite, request)%>' />

<%


    String baseImagePath = currentSite.getImagePath(); //storefront image directory, preceded by domain //
    String localBaseImagePath = "/assets/amana/images/";
	currentSite.getString("DOMAIN");
	request.setAttribute("AMA_productDetailPage","Y");
    String productName;
    String productModel;
    String defaultImageUrl;
    String prodLgVartImage;
    String prodMediumDescription;
    List prodVariants;
    boolean showMSRP;
    boolean enableShoppingCart;
    String noProductImageName = "no_image_290x290.jpg";
    String noProductImage = "";

    String parentCategoryId = null;
    String categoryId = null;

    List productFiles;
    boolean hasDemoVideo = false;
    String demoVideoUrl = "";
    /*
   Get product Id
    */
    String productId = (request.getParameter("productId") == null) ? "" : request.getParameter("productId");
    Product product = null;
    /*
   Get product
    */
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

    /*
    Check if product has a demo video.
    */
    try {
        productFiles = product.getEntityFiles(true);
        Iterator itProductFiles = productFiles.iterator();
        while (itProductFiles.hasNext()){
            EntityFile file = (EntityFile) itProductFiles.next();
            String referenceKey = file.getString("REFERENCE_KEY");
            if ("ZDEMOVIDEO".equals(referenceKey)) {
                hasDemoVideo = true;
                demoVideoUrl = file.getString("FILE_URL");
            }
        }
    } catch (Exception ex) {
        productFiles = null;
    }

    /*
   Get category and parent category
    */
    parentCategoryId = (request.getParameter("parentCategoryId") == null) ? "" : request.getParameter("parentCategoryId");
    categoryId = (request.getParameter("categoryId") == null) ? "" : request.getParameter("categoryId");

    // Remove XSS codes
    if(MultiSiteWebUtil.containXSS(parentCategoryId)){
        parentCategoryId = MultiSiteWebUtil.removeXSS(parentCategoryId);
    }
    if(MultiSiteWebUtil.containXSS(categoryId)){
        categoryId = MultiSiteWebUtil.removeXSS(categoryId);
    }

    Category category = null;
    Category parentCategory = null;
    if (!StringUtil.isEmpty(categoryId) && StringUtil.isLong(categoryId)) {
        try {
            category = CategoryManager.getCategory(Long.parseLong(categoryId));
        } catch (Exception ex) {
            category = null;
            System.out.println(ex.getMessage());
        }
    } else {
        List listCategory = product.getCategories();
        if (listCategory != null && listCategory.size() > 0) {
            category = (Category) listCategory.get(0);
        }
    }
    if (!StringUtil.isEmpty(parentCategoryId) && StringUtil.isLong(parentCategoryId)) {
        try {
            parentCategory = CategoryManager.getCategory(Long.parseLong(parentCategoryId));
        } catch (Exception ex) {
            parentCategory = null;
            System.out.println(ex.getMessage());
        }
    } else {
        parentCategory = CatalogUtils.getRootCategoryFromProduct(product);
    }

    /*
   Check whether or not show MSRP
    */
    showMSRP = !"N".equals(currentSite.getString("PROD_BROWSE_DISPLAY_MSRP"));
    enableShoppingCart = !"N".equals(currentSite.getString("ENABLE_SHOPPING_CART"));
    if (product != null) {
        /*
       Get product name
        */
        productName = product.getString("NAME") == null ? "" : product.getString("NAME");
        /*
       Get product model
        */
        productModel = product.getString("STYLE") == null ? "" : product.getString("STYLE");
        /*
        Get product medium Description
        */
        prodMediumDescription = product.getString("MEDIUM_DESCRIPTION") == null ? "" : product.getString("MEDIUM_DESCRIPTION");

        /*
          Check whether or not show energy star logo
          */
        boolean showEnergyStar = !"N".equals(product.getString(WhirlpoolProductManager.ENERGY_STAR_FLAG_KEY));


        /*
       Get product variant
        */
        try {
            prodVariants = product.getProductVariants();
        } catch (Exception ex) {
            prodVariants = null;
            System.out.println(ex.getMessage());
        }
        /*
        Sort sales models by DEFAULT_PRODUCT_VARIANT_SORT_TYPE
        */
        // Get sort type
        String saleModelSortType = currentSite.getString("DEFAULT_PRODUCT_VARIANT_SORT_TYPE");
        // Init comparator
        ProductVariantComparator comparator = new ProductVariantComparator();
        // Set sort type
        comparator.setCompareBy(saleModelSortType);
        // Sort product variant by sort type
        Collections.sort(prodVariants, comparator);

        defaultImageUrl = MultiSiteWebUtil.getDefaultProductImagePath(currentSite, prodVariants);

        /*
       Get larger image
        */
        Map largeImages = MultiSiteWebUtil.populateDefaultImageMappings(currentSite, product);
        /*
       Get large product image
        */
        prodLgVartImage = (String) largeImages.get(defaultImageUrl);

        /*
       Link
        */
        String largerImage = "javascript:openWindow('/catalog/product_amana_popup.jsp?productId=" + productId + "&defaultImageUrl=" + defaultImageUrl + "','larger_image',700,770)";
        String sendEmail = "javascript:openNamedWindow('/catalog/email_popup.jsp?parentCategoryId=" + parentCategoryId + "&categoryId=" + categoryId + "&productId=" + productId + "','email_a_friend',500,600,'scrollbars')";
        String print = "/catalog/product_amana_printable.jsp?parentCategoryId=" + parentCategoryId + "&categoryId=" + categoryId + "&productId=" + productId;
        String shopNowURL = "/content.jsp?pageName=CIProductDetail&cii_nProductId=" + productId;
        /*get parent product. This variable fix bug: breadcrumb on accessory detail page must be the same parent product*/
        String parentProductId = (request.getParameter("parentProductId") == null) ? "" : request.getParameter("parentProductId");
        //Product subtile
        String subTitle = (String) product.get("SUB_TITLE");
        /*
       Get parent product
        */
        Product parentProduct = null;
        String parentProductName = "";
        if (!StringUtil.isEmpty(parentProductId) && StringUtil.isLong(parentProductId)) {
            try {
                parentProduct = ProductManager.getProduct(Long.parseLong(parentProductId));
            } catch (Exception ex) {
                parentProduct = null;
                System.out.println(ex.getMessage());
            }
        }
        if (parentProduct != null) {
            /*
           Get product name
            */
            parentProductName = parentProduct.getString("NAME") == null ? "" : parentProduct.getString("NAME");
        }
        ArrayList altImages = MultiSiteWebUtil.getAltImages(currentSite, product);
        String altImage;
        String altLgImage;
        Map altLgImages = MultiSiteWebUtil.populateAltImageMappings(currentSite, product);

        String showEmailPopup = (String) currentSite.get("PROD_DETAIL_DISPLAY_EMAIL_LINK");
        String showPrint = (String) currentSite.get("PROD_DETAIL_DISPLAY_PRINT_LINK");
        String showStoreLocator = (String) currentSite.get("PROD_DETAIL_DISPLAY_STORELOCATOR_LINK");

        String onclickStoreLocator = "";
        if (parentCategory != null && category != null) {
            onclickStoreLocator = "dcsMultiTrack('WT.tx_e','locstore','WT.cg_n','Product Categories;"+parentCategory.getString("DESCRIPTION")+";Product Details;"+category.getString("DESCRIPTION")+"','WT.cg_s','Locate a Store;"+category.getString("DESCRIPTION")+";Locate a Store;Locate a Store');";
        }
        String additionalImgDCS="";
        
        /*
		Get Specifications list
		 */
		LinkedHashMap specifications;
		LinkedHashMap specifications1;
		try {
			String groupType= currentSite.getString("SP_GROUP_TYPE");
			specifications = (LinkedHashMap)WhirlpoolProductAttributeGroupManager.findProductAttributeGroupsSorted(Long.parseLong(productId), groupType, true);
			specifications1 = (LinkedHashMap)WhirlpoolProductAttributeGroupManager.findProductAttributeGroupsSorted(Long.parseLong(productId), "ER1", true);
		} catch (Exception ex) {
			specifications = null;
			specifications1 = null;
			System.out.println(ex.getMessage());
		}

%>

<script src="/assets/amana/xml/selfselect/jquery.cookie.js"></script>
<script src="/assets/amana/js/jquery.reel-1.2.1-bundle.js"></script>
<script src="/assets/amana/js/www-embed-vflomk1Pn.js"></script>

<script language="JavaScript" type="text/javascript">
    function swatchProductImage(imageUrl, largeImageUrl, swatchId, index, type) {
        var variantSize = <%=prodVariants.size()%>;
        var altSize = <%=altImages.size()%>;
        /*
         Set hidden value
         */
        if (type == "Variant") {
            document.productForm.vartIndex.value = index;
            document.productForm.imageUrl.value = imageUrl;
            document.productForm.addIndex.value = '';
        } else if (type == "Addition") {
            document.productForm.imageUrl.value = imageUrl;
            document.productForm.vartIndex.value = '';
            document.productForm.addIndex.value = index;
        }
        /*
         Change product photo
         */
        var url = "<a href=\"javascript:openWindow(\'/catalog/product_amana_popup.jsp?productId=<%=productId%>&defaultImageUrl=" + imageUrl + "\',\'larger_image\',700,770)\"><img src=\"" + imageUrl + "\" /></a>";

        document.getElementById("productImage").innerHTML = url;
        var viewLarger = '<%=I18NUtil.getString(SiteManager.getLocale(currentSite, request), "product_info.View_Larger", "View Larger")%>';
        /*
         Change large Image Url
         */
        document.productForm.largeImageUrl.value = largeImageUrl;
        url = "<a id=\"cat-pro-view-lrg-img\" class=\"fr\" href=\"javascript:openWindow(\'/catalog/product_amana_popup.jsp?productId=<%=productId%>&defaultImageUrl=" + imageUrl + "\',\'larger_image\',700,770)\">" + viewLarger + "</a>";
        url += "<img alt='" + viewLarger + "' src=\"<%=baseImagePath + "home/arrow.gif"%>\"/>";
        if (document.getElementById("largerImage") != null) {
            document.getElementById("largerImage").innerHTML = url;
        }
        /*
         Change swatch status
         */

        var theSwatchImg = $(".swatch-img");
        var totalSwatches = theSwatchImg.length;

        for(var i = 0; i < totalSwatches; i++) {

            theSwatchImg[i].id = "";

        }

        theSwatchImg[index].id = "cat-pro-current-swatch";


        /*
         Change additional image status
         */
        var statusContent;
        for (var i = 0; i < altSize; i++) {
            var variantId = "additionalImage"  + i;
            if (variantId != swatchId) {
                statusContent = document.getElementById(variantId).innerHTML;
                statusContent = statusContent.replace("FONT-WEIGHT: bold", "font-weight: normal");
                document.getElementById(variantId).innerHTML = statusContent;
            } else {
                statusContent = document.getElementById(swatchId).innerHTML;
                statusContent = statusContent.replace("FONT-WEIGHT: normal", "font-weight: bold");
                document.getElementById(swatchId).innerHTML = statusContent;
            }

        }
    }

    function swatchAltProductImage(imageUrl, largeImageUrl, swatchId, index,type) {
    <%--var variantSize = <%=altImages.size()%>;--%>
        /*
         Set hidden value
         */
        if (type == "Variant") {
            document.productForm.vartIndex.value = index;
            document.productForm.imageUrl.value = imageUrl;
            document.productForm.addIndex.value = '';
        } else if (type == "Addition") {
            document.productForm.imageUrl.value = imageUrl;
            document.productForm.vartIndex.value = '';
            document.productForm.addIndex.value = index;
        }
        /*
         Change product photo
         */
        var url = "<a href=\"javascript:openWindow(\'/catalog/product_amana_popup.jsp?productId=<%=productId%>&defaultImageUrl=" + imageUrl + "\',\'larger_image\',700,770)\"><img src=\"" + imageUrl + "\" /></a>";

        document.getElementById("productImage").innerHTML = url;
        var viewLarger = '<%=I18NUtil.getString(SiteManager.getLocale(currentSite, request), "product_info.View_Larger", "View Larger")%>';
        /*
         Change large Image Url
         */
        document.productForm.largeImageUrl.value = largeImageUrl;
        url = "<a id=\"cat-pro-view-lrg-img\" class=\"fr\" href=\"javascript:openWindow(\'/catalog/product_amana_popup.jsp?productId=<%=productId%>&defaultImageUrl=" + largeImageUrl + "\',\'larger_image\',700,770)\">" + viewLarger+ "</a>";
        if (document.getElementById("largerImage") != null) {
            document.getElementById("largerImage").innerHTML = url;
        }
    }

    function printProduct() {
        dcsMultiTrack('WT.ti', 'Page Printed', 'WT.tx_e', 'printed');
        var url = "<%=print%>";
        var objValue = document.productForm.tabName.value;
        if (objValue != '') {
            url = url + "&tabName=" + objValue;
        }

        objValue = document.productForm.vartIndex.value;
        if (objValue != '') {
            url = url + "&vartIndex=" + objValue;
        }
        objValue = document.productForm.addIndex.value;
        if (objValue != '') {
            url = url + "&addIndex=" + objValue;
        }
        objValue = document.productForm.imageUrl.value;
        if (objValue != '') {
            url = url + "&imageUrl=" + objValue;
        }

        //openWindow(url, 'product_print',565,580);
        window.open(url, 'product_print', 'height=565,width=615,status=yes,toolbar=no,menubar=no,location=no,directories=no,resizable=no,scrollbars=yes,titlebar=no');
    }
    
    $(document).ready(function() {
    	$(".left_nav_item:first").css("display","block");
    });
    
    function changeProductColor(index) {
    	$(".left_nav_item").css("display","none");
    	var productItems = $(".left_nav_item");
    	var selectedItem =  productItems.get(index);
    	$(selectedItem).css("display","block");
    }
    
</script>

<script type="text/javascript">
	allProdInfo = {
		curOn:0,
		prodInfo:[]
	}

</script>

<div class="pdp_dim-lights" style=""></div>
<div id="mainContentWrap">
<div id="pdp_Wrapper">
<div id="cat-pro-top-background">
	<div id="cat-pro-top-wrapper">
		<div id="cat-pro-top-blocker"></div>
	
		<div id="cat-pro-top-wrapper-content">
		
			
			<div id="productImage" style="z-index:1">
			
					<div id="image360_small_wrap" >
						<img id="image-360-small" class="hide" src="" width="843" height="625" />
						<div id="reelZoomInButton" class="zoom-button in">&#x38;</div>
						
							
							
						<img src="/assets/amana/images/360/360-icon.png" id="image360icon">
							
					</div>
					<div id="image360_large_wrap" >
						<img id="image-360-large" class="hide" src="" width="1200" height="850" />
						<div id="reelZoomOutButton" class="zoom-button out">&#x39;</div>
					
					</div>
					
					<div id="cat-pro-feat-logos">
						<ul>
							<li>
								<img src="/assets/amana/images/sitesection/product/PDP_estarLogo.gif" alt="Energy Star Logo">
								<p>Learn what it means</p>
							</li>
						</ul>
					</div>
							
			<%--
				<%
					if (defaultImageUrl != null && !"".equals(defaultImageUrl)) {
				%>
				<html:img styleClass="productImage" env="images" src="<%=prodLgVartImage%>" alt='<%=productName%>'/>
				<%
				} else {
					noProductImage=MultiSiteWebUtil.getProductImage(currentSite, WhirlpoolProductManager.DIRECTORY_PREFIX_STDDEFAULT + "/" + noProductImageName);
				%>
				<html:img env="images" src="<%=noProductImage%>" alt='<%=productName%>'/>
				<%}%>
			--%>
			</div>
			
		
			<div id="pro-info-nav-wraper">
				<div id="pro-info-nav">

				<%
					boolean hasDefault = false;
					boolean hasVartImage;
					//boolean hasLgVartImage = true;
					String swatchImage;
					String prodVariantImage;
					ProductVariant prodVariant;
					String colorDCS="";
					ArrayList swatches = new ArrayList();
					ArrayList colorDCSs = new ArrayList();
					ArrayList hasVartImages = new ArrayList();
					ArrayList swatchNames = new ArrayList();
					ArrayList colorCodes = new ArrayList();
					
					String height = "";
					String width = "";
					String depth = "";
					
					try {
						String groupType= currentSite.getString("SP_GROUP_TYPE");
						specifications = (LinkedHashMap)WhirlpoolProductAttributeGroupManager.findProductAttributeGroupsSorted(Long.parseLong(productId), groupType, true);
					} catch (Exception ex) {
						specifications = null;
						System.out.println(ex.getMessage());
					}

					Set keySetSpecs = specifications.keySet();
					
					%>
					<logic:iterator id="keySpec" type="java.lang.Object" collection="<%=keySetSpecs%>">
					<%
					/* Get dimensions of product */
						SortedSet prodSpecs = (SortedSet) specifications.get(keySpec);
						if("Dimensions".equalsIgnoreCase((String)keySpec)){
							%>
							<logic:iterator id="prodSpec" type="com.fry.wp.multisite.catalog.ProductFeature" collection="<%=prodSpecs%>">
							<%
							if("Refrigeration".equalsIgnoreCase(parentCategory.getString("NAME"))){
								String specName = prodSpec.getName();
								if(specName.toLowerCase().contains("Height To Top of Door Hinge".toLowerCase())){
									height = prodSpec.getValue();
								}
								else if(specName.toLowerCase().contains("Depth Closed Including Handles".toLowerCase())){
									depth = prodSpec.getValue();
								}
								else if(specName.toLowerCase().contains("Width of Cabinet Only".toLowerCase())){
									width = prodSpec.getValue();
								}
							}
							else if("Dishwashers".equalsIgnoreCase(parentCategory.getString("NAME"))){
								
							}
							else if("Cooking".equalsIgnoreCase(parentCategory.getString("NAME"))){
								String specName = prodSpec.getName();
								if(specName.toLowerCase().contains("Overall Height".toLowerCase())){
									height = prodSpec.getValue();
								}
								else if(specName.toLowerCase().contains("Overall Depth".toLowerCase())){
									depth = prodSpec.getValue();
								}
								else if(specName.toLowerCase().contains("Overall Width".toLowerCase())){
									width = prodSpec.getValue();
								}
							}
							else if("Laundry".equalsIgnoreCase(parentCategory.getString("NAME"))){
								String specName = prodSpec.getName();
								if(specName.toLowerCase().contains("Height".toLowerCase()) || specName.toLowerCase().contains("Product Height".toLowerCase())){
									height = prodSpec.getValue();
								}
								else if(specName.toLowerCase().contains("Depth".toLowerCase()) || specName.toLowerCase().contains("Product Depth".toLowerCase())){
									depth = prodSpec.getValue();
								}
								else if(specName.toLowerCase().contains("Width".toLowerCase()) || specName.toLowerCase().contains("Product Width".toLowerCase())){
									width = prodSpec.getValue();
								}
							}
							%>
							</logic:iterator>
					<%	
						}
					%>	
					</logic:iterator>
					<%
					for (int i = 0; i < prodVariants.size(); i++) {
						prodVariant = (ProductVariant) prodVariants.get(i);
						/* Get variant image */
						prodVariantImage = MultiSiteWebUtil.getDefaultImagePath(currentSite, prodVariant);
						/* Get large variant image */
						prodLgVartImage = (String) largeImages.get(prodVariantImage);
						/* Get swatch image */
						if (prodVariantImage != null) {
							if (!hasDefault) {
								hasDefault = true;
								swatchImage = baseImagePath + "/color_bar/" + prodVariant.getString("COLOR_CODE") + "-off.gif";
							} else {
								swatchImage = baseImagePath + "/color_bar/" + prodVariant.getString("COLOR_CODE") + "-off.gif";
							}
							hasVartImage = true;
						} else {
							swatchImage = baseImagePath + "/color_bar/" + prodVariant.getString("COLOR_CODE") + "-off.gif";
							hasVartImage = false;
						}
						swatches.add(swatchImage);
						String swatchName = prodVariant.getString("COLOR_NAME");
						colorDCS="dcsMultiTrack('WT.tx_e','photos','WT.cg_n','Product Categories;Product Details;','WT.cg_s','Photos;Photos;Photos','DCSext.color','"+swatchName+"');";
						if (parentCategory != null && category != null) {
							colorDCS = "dcsMultiTrack('WT.tx_e','photos','WT.cg_n','Product Categories;" + parentCategory.getString("DESCRIPTION") + ";Product Details;" + category.getString("DESCRIPTION") + "','WT.cg_s','Photos;"+category.getString("DESCRIPTION")+";Photos;Photos','DCSext.color','"+swatchName+"');";
						}
						colorDCSs.add(colorDCS);
						hasVartImages.add(new Boolean(hasVartImage));
						colorCodes.add(prodVariant.getString("COLOR_CODE"));
						swatchNames.add(swatchName);
					}
					for (int i = 0; i < prodVariants.size(); i++) {
						/* generate left_nav_item div for each product variant*/
						prodVariant = (ProductVariant) prodVariants.get(i);
						String colorCode = (String) colorCodes.get(i);
						String swatchName = (String)swatchNames.get(i);
						/* Get large variant image */
						prodVariantImage = MultiSiteWebUtil.getDefaultImagePath(currentSite, prodVariant);
						prodLgVartImage = (String) largeImages.get(prodVariantImage);
						largerImage = "javascript:openWindow('/catalog/product_amana_popup.jsp?productId=" + productId + "&defaultImageUrl=" + prodLgVartImage + "','larger_image',700,770)";
					%>
					<script type="text/javascript">
						allProdInfo.prodInfo[<%=i%>] = {
								html: {
									productName:'<%=productName%>',
									model:'<%=prodVariant.getString("SKU")%>',
									price:"<%=MultiSiteWebUtil.getPrice(prodVariant)%>",
									largeImage:"<%=prodLgVartImage%>",
									dims:{
										width:'<%= width.replaceAll(" Inches", "\"")  %>',
										height:'<%= height.replaceAll(" Inches", "\"")  %>',
										depth:'<%= depth.replaceAll(" Inches", "\"")  %>'
									},
									wtb:'<%=shopNowURL + "&cii_sSKU=" + prodVariant.getString("SKU")%>',
									ig:"<%=largerImage%>",
									email:"<%=sendEmail%>",
									print:"<%=print%>",
									small360:"/assets/amana/images/360/size-test-small-reel.jpeg",
									large360:"/assets/amana/images/360/size-test-large.jpg",
									base360Dir:"/assets/amana/images/360/",
									video:"AtSLj92yaTc"
								},
								colorCode:'<%=colorCode%>',
								swatches:[]
							}
					</script>
					<% if (product.getString("STYLE").equals(prodVariant.getString("SKU"))) {%>
					<script type="text/javascript">
						allProdInfo.curOn = <%=i%>
					</script>
					<div class="left_nav_item" id='<%="swatch " + colorCode%>' style="display:none">
						<div>
							<h1 id="productName"><%=productName%></h1>
							<p id="model"><%=prodVariant.getString("SKU")%></p>
						</div>
						<div class="msrpWrapper">
							<p>
								<logic:if expression="<%=showMSRP%>">
									<span id="price"><%=MultiSiteWebUtil.getPrice(prodVariant)%></span> <span id="msrp">MSRP</span>
								</logic:if>
							</p>
						</div>
						<div id="dims">
							<ul>
								<li><span class="dimType">H</span> <span id="height" class="dims"><%=height.replaceAll(" Inches", "\"")%></span></li>
								<li><span class="dimType">D</span> <span id="depth" class="dims"><%=depth.replaceAll(" Inches", "\"")%></span></li>
								<li><span class="dimType">W</span> <span id="width" class="dims"><%=width.replaceAll(" Inches", "\"")%></span></li>
							</ul>
						</div>
						<div id="swatches">
							<ul>
								<% } %>
								<logic:iterator id="swatch" collection='<%=swatches%>' indexId='index' type="String">
									<%
									Boolean hasImage = (Boolean)hasVartImages.get(index);
									colorCode = (String) colorCodes.get(index);
									colorDCS = (String)colorDCSs.get(index);

									String onclick = "changeProductColor(" + index +");";
									if(hasImage){
										onclick += colorDCS;
									}
									%>

									<script type="text/javascript">
										allProdInfo.prodInfo[<%=i%>].swatches.push(
											{
												colorDCS:"<%=colorDCS%>",
												metrics:<%=hasImage%>
											}
										)
									</script>
									<% if (product.getString("STYLE").equals(prodVariant.getString("SKU"))) {%>
									<li class="<%="swatch-img "  + colorCode%>"></li>
									<% } %>
								</logic:iterator>
							<% if (product.getString("STYLE").equals(prodVariant.getString("SKU"))) {%>
							</ul>
						</div>
						<div id="pop-outs">
							<ul>
								<li id="wtb">
									<a data="<%=shopNowURL + "&cii_sSKU=" + prodVariant.getString("SKU")%>"><span class="icon-feature icon">3</span>Where to Buy<span class="icon-arrow icon">5</span></a>
								</li>
								<li id="ig">
									<a data="<%=largerImage%>"><span class="icon-feature icon">4</span>Image gallery<span class="icon-arrow icon">5</span></a>
								</li>
								<li id="vid">
									<a data="<%=largerImage%>"><span class="icon-feature icon">2</span>Video<span class="icon-arrow icon">5</span></a>
								</li>
								
							</ul>
						</div>
					</div>
					
					<%} }%>
					
				</div>
				
				
					<div class="wtb-panel overlay" style="background-color:red">
						<iframe src="http://amanalocator.arsplatform.com/" width="700" height="460" frameborder="0" marginwidth="0" marginheight="0" scrolling="no"></iframe>

						
						<div id="productFlyoutClose" class="fadeElement js_closeButton">
							<div class="opac"> </div>
							<div class="closeButton" >9</div>
						</div>
					</div>
				
					<jsp:include page="product_amana_gallery.jsp"> 
						  <jsp:param name="productId" value="<%=productId%>"/>   
					  </jsp:include> 

					
					<%--
					<div id="ig-panel" class="ig-panel overlay">
					
					
					
					
						<img src="fred.jpg" id="productImageTransition_from" class="productGalery_image">
						<img src="fred.jpg" id="productImageTransition_to" class="productGalery_image">
						
						<div id="productFlyoutClose" class="fadeElement js_closeButton">
							<div class="opac"> </div>
							<div class="closeButton" >9</div>
						</div>
						
						
						<div id="productGalery_expand" class="fadeElement">
							<div class="opac"> </div>
							<div class="icon_productGalery expandDiv" > </div>
						</div>
						
						
						<div id="productGalery_arrowLeft" class="fadeElement">
							<div class="opac "> </div>
							<div class="icon_productGalery arrowDiv" > </div>
						</div>
						<div id="productGalery_arrowRight" class="fadeElement">
							<div class="opac"> </div>
							<div class="icon_productGalery arrowDiv" > </div>
						</div>
						
						
						
						
						
						<div class="productGallery_thumbnail_wrapper fadeElement">
							<div class="supportDiv opac"></div>
							<div id="productGalery_div" class="supportDiv ">
								<ul id="productGalery_thumbnails">
									<li></li>
									<li></li>
								<ul>
							
							</div>
						</div>
						
						
					</div>
					--%>
					<div id="vid-panel" class="vid-panel overlay" style="">
						<div class="vid-panel-wrapper">
							<div id="videoDiv"></div>
							<%--<iframe width="700" height="394" frameborder="0" allowfullscreen="" src="http://www.youtube.com/embed/AtSLj92yaTc?rel=0" ></iframe> --%>
						</div>
						<div id="productFlyoutClose" class="fadeElement js_closeButton">
							<div class="opac"> </div>
							<div class="closeButton" >9</div>
						</div>
					</div>
					
				<div>
					<ul id="share">
						<%if (!StringUtil.isEmpty(showEmailPopup) && "Y".equals(showEmailPopup)) {%>
							<li id="email">
								<a href='javaScript:binder.productInfoGroup.email("topViewControler");void(0)'>
									<%=I18NUtil.getString(SiteManager.getLocale(currentSite, request), "product_body.email", "Email")%>
								</a>
							</li>
						<%}%>
							<%if (!StringUtil.isEmpty(showPrint) && "Y".equals(showPrint)) {%>
						<li id="print">
							<a href='javaScript:binder.productInfoGroup.print("topViewControler");void(0)'>
								<%=I18NUtil.getString(SiteManager.getLocale(currentSite, request), "product_body.print", "Print")%>
							</a>
						</li>
		<%}%>
					</ul>
				</div>
			</div>
		</div>
	</div>
</div>



<% request.setAttribute("specifications", specifications);
request.setAttribute("specifications1", specifications1);
%>   
  <jsp:include page="product_amana_info.jsp">
      <jsp:param name="productId" value="<%=productId%>"/>  
  </jsp:include> 
  <logic:if expression="<%=showMSRP%>">
      <div id="cat-pro-msrp">
          <i18n:message key="product_compare.Imformation">*MSRP is Manufacturer's Suggested Retail Price and may not necessarily be the price at which the product is sold in the consumer's area. Dealer alone determines actual price.</i18n:message>
      </div>
  </logic:if>

<script type="text/javascript">
	binder.extend()
	tableStripe()
	
		
		
		
			$(document).ready(function(){
		
			
			binder.productInfoGroup.create(
				"topViewControler",
				{
					curOn:allProdInfo.curOn,
					prodInfo:allProdInfo.prodInfo
				}
			)
			/*
			binder.disolveGroup.create(
				"productImage",
				{
					imgAry:[
						"/assets/amana/images/products/img_0.jpg",
						"/assets/amana/images/products/img_1.jpg"
					]
				}
			)
			
			
			binder.colorSwatchNavGroup.create(
				"swatchNav",
				allProdInfo
			);
			
			
			
			binder.slideout.create(
				"sliderout0",
				{}
			);
			*/
			
			
		
		
		/*
		$('#image-360-small').reel({
		  footage:		43,
		  frames:		43,
		  rows:			0,
		  cursor:		'hand',
		  cw:			false,
		  horizontal:	true,
		  loops:		false,
		  frame:		25,
		  opening:		.55,
		  entry:		.75,
		  throwable:	true
		});
		
		$('#image-360-small').on(
			'loaded', 
			function(){
				debugger;
			}
		)
		
		//TweenMax.to($("#image-360-small-reel"), 0, {scale:.7, transformOrigin:"50% 0px"});
		
		$(".zoom-button.in").click(function() {
			$('.zoom-button.out').removeClass('hide');
			TweenMax.to($(".overlay"), 0, {autoAlpha:0});
			TweenMax.to($(".overlay"), 0, {width:0});
			TweenMax.fromTo($(".zoom-button.out"), 0, {autoAlpha:0}, {autoAlpha:1});
			TweenMax.fromTo($(".zoom-button.in"), 0, {autoAlpha:1}, {autoAlpha:0});
			TweenMax.to($("#image-360-large-reel"), .5, {scale:1, delay:.5, ease:Power0.easeOut});
			TweenMax.to($(".module, #360-icon"), .5, {autoAlpha:0});
			TweenMax.to($(".main"), .5, {height:900, delay:.5, ease:Power0.easeOut});
			TweenMax.to($(".dim-lights"), .5, {css:{autoAlpha:0}});
		});
		
		$(".zoom-button.out").click(function() {
			$('.zoom-button.out').addClass('hide');
			TweenMax.fromTo($(".zoom-button.in"), 0, {autoAlpha:0}, {autoAlpha:1});
			TweenMax.fromTo($(".zoom-button.out"), 0, {autoAlpha:1}, {autoAlpha:0});
			TweenMax.to($("#image-360-large-reel"), .5, {scale:.7, ease:Power0.easeOut});
			TweenMax.to($(".module, #360-icon"), .5, {autoAlpha:1, delay:.5});
			TweenMax.to($(".main"), .5, {height:600, ease:Power0.easeOut});
		});
		
		$(".where-to-buy").click(function() {
			TweenMax.fromTo($(".where-to-buy-panel"), .5,{width:0}, {width:700, ease:Power0.easeOut, delay:.5});
			TweenMax.to($(".dim-lights"), .5, {autoAlpha:.5, delay:1});
			TweenMax.fromTo($(".close"), .5, {autoAlpha:0}, {autoAlpha:.65, delay:1});
			TweenMax.to($(".overlay"), 0, {autoAlpha:1});
			TweenMax.to($(".image-gallery-panel, .video-panel"), .5, {width:0});
			TweenMax.fromTo($(".map-circle"), .5, {autoAlpha:0}, {autoAlpha:1, delay:1});
			TweenMax.from($(".marker-1"), .75, {top:-50, ease:Bounce.easeOut, delay:1.4});
			TweenMax.from($(".marker-2"), .75, {top:-50, ease:Bounce.easeOut, delay:1.6});
			TweenMax.from($(".marker-3"), .75, {top:-50, ease:Bounce.easeOut, delay:1.8});
		});
		
		$("#ig").click(function() {
			TweenMax.fromTo($(".image-gallery-panel"), .5,{width:0}, {width:700, ease:Power0.easeOut, delay:.5});
			TweenMax.to($(".dim-lights"), .5, {autoAlpha:.5, delay:1});
			TweenMax.fromTo($(".close"), .5, {autoAlpha:0}, {autoAlpha:.65, delay:1});
			TweenMax.to($(".overlay"), 0, {autoAlpha:1});
			TweenMax.to($(".where-to-buy-panel, .video-panel"), .5, {width:0});
		});
		
		$(".video").click(function() {
			TweenMax.fromTo($(".video-panel"), .5,{width:0}, {width:700, ease:Power0.easeOut, delay:.5});
			TweenMax.to($(".dim-lights"), .5, {autoAlpha:.5, delay:1});
			TweenMax.fromTo($(".close"), .5, {autoAlpha:0}, {autoAlpha:.65, delay:1});
			TweenMax.to($(".overlay"), 0, {autoAlpha:1});
			TweenMax.to($(".where-to-buy-panel, .image-gallery-panel"), .5, {width:0});
			TweenMax.fromTo($(".video-panel iframe"), .5, {autoAlpha:0}, {autoAlpha:1, delay:1});
		});
		
		$(".overlay .close").click(function() {
			TweenMax.to($(".overlay"), .5, {css:{width:0}, ease:Power0.easeOut, delay:.5});
			TweenMax.to($(".dim-lights"), .5, {autoAlpha:0, delay:1});
			TweenMax.to($(".video-panel iframe"), .5, {autoAlpha:0});
		});
		
		$(".image-gallery-panel").click(function() {
			TweenMax.to($(".image-gallery-2"), .5, {autoAlpha:1});
		});
		*/
	});
	
</script>



<%}%>

</div>