#' Add tool
#'
#' Add a tool to the scRNA-tools database
#'
#' @param database Database object
#' @param pkgs_cache Packages cached object
#'
#' @return Database with added tool
add_tool <- function(database, pkgs_cache) {

    licenses <- get_tools(database$Tools)$License
    spdx_licenses <- load_spdx_licenses()
    
    cat("\n")
    usethis::ui_todo("Please enter the details of the new tool to add")
    cat("\n")

    name <- prompt_name(database)
    matches <- search_name(database, name)

    if (length(matches) > 1) {
        usethis::ui_info(glue::glue(
            "These tools with similar names already exist in the database: ",
            "{usethis::ui_value(matches)}"
        ))
        continue <- prompt_yn("Do you want to continue (y/n)?:")

        if (!continue) {
            return(database)
        }
    }
    
    platform     <- prompt_platform()
    code         <- prompt_code()
    license      <- prompt_license(licenses, spdx_licenses)
    dois         <- prompt_dois()
    refs         <- get_references(dois, database$RefLinks)
    dois         <- refs$DOI
    description  <- prompt_description()
    categories   <- prompt_categories(database)

    tool <- new_sctool(name, platform, code, license, description, dois,
                       categories)

    database$Tools[[name]] <- tool
    database <- update_github(name, database)
    database <- update_repositories(name, database, pkgs_cache, prompt = FALSE)

    database$References <- dplyr::bind_rows(database$References, refs)
    database$RefLinks <- dplyr::bind_rows(
        database$RefLinks,
        attr(refs, "Links")
    )

    usethis::ui_done(glue::glue(
        "Added {usethis::ui_value(name)} to database"
    ))

    cat("\n")
    usethis::ui_todo("Please check the new tool is correct")
    cat("\n")
    print(database$Tools[[name]])

    correct <- prompt_yn("\nIs this correct (y/n)?")

    if (!correct) {
        database <- update_tool(database, pkgs_cache, name)
    }

    set_gitmessage_add(tool$Tool, tool$Description)

    return(database)
}
