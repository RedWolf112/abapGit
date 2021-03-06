CLASS zcl_abapgit_gui_page_main DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC INHERITING FROM zcl_abapgit_gui_page.

  PUBLIC SECTION.
    INTERFACES: zif_abapgit_gui_hotkeys.
    METHODS:
      constructor
        RAISING zcx_abapgit_exception,
      zif_abapgit_gui_event_handler~on_event REDEFINITION.


  PROTECTED SECTION.
    METHODS:
      render_content REDEFINITION.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_actions,
        show          TYPE string VALUE 'show' ##NO_TEXT,
        changed_by    TYPE string VALUE 'changed_by',
        overview      TYPE string VALUE 'overview',
        documentation TYPE string VALUE 'documentation',
        changelog     TYPE string VALUE 'changelog',
        select        TYPE string VALUE 'select',
        apply_filter  TYPE string VALUE 'apply_filter',
        abapgit_home  TYPE string VALUE 'abapgit_home',
      END OF c_actions.

    DATA: mo_repo_overview TYPE REF TO zcl_abapgit_gui_repo_over,
          mv_repo_key      TYPE zif_abapgit_persistence=>ty_value.

    METHODS test_changed_by
      RAISING zcx_abapgit_exception.

    METHODS render_scripts
      RETURNING
        VALUE(ro_html) TYPE REF TO zcl_abapgit_html
      RAISING
        zcx_abapgit_exception.

    METHODS build_main_menu
      RETURNING VALUE(ro_menu) TYPE REF TO zcl_abapgit_html_toolbar.


ENDCLASS.



CLASS zcl_abapgit_gui_page_main IMPLEMENTATION.

  METHOD build_main_menu.

    DATA: lo_advsub  TYPE REF TO zcl_abapgit_html_toolbar,
          lo_helpsub TYPE REF TO zcl_abapgit_html_toolbar.

    CREATE OBJECT ro_menu EXPORTING iv_id = 'toolbar-main'.
    CREATE OBJECT lo_advsub.
    CREATE OBJECT lo_helpsub.

    lo_advsub->add( iv_txt = 'Database util'
                    iv_act = zif_abapgit_definitions=>c_action-go_db ) ##NO_TEXT.
    lo_advsub->add( iv_txt = 'Package to zip'
                    iv_act = zif_abapgit_definitions=>c_action-zip_package ) ##NO_TEXT.
    lo_advsub->add( iv_txt = 'Transport to zip'
                    iv_act = zif_abapgit_definitions=>c_action-zip_transport ) ##NO_TEXT.
    lo_advsub->add( iv_txt = 'Object to files'
                    iv_act = zif_abapgit_definitions=>c_action-zip_object ) ##NO_TEXT.
    lo_advsub->add( iv_txt = 'Test changed by'
                    iv_act = c_actions-changed_by ) ##NO_TEXT.
    lo_advsub->add( iv_txt = 'Debug info'
                    iv_act = zif_abapgit_definitions=>c_action-go_debuginfo ) ##NO_TEXT.
    lo_advsub->add( iv_txt = 'Settings'
                    iv_act = zif_abapgit_definitions=>c_action-go_settings ) ##NO_TEXT.

    lo_helpsub->add( iv_txt = 'Tutorial'
                     iv_act = zif_abapgit_definitions=>c_action-go_tutorial ) ##NO_TEXT.
    lo_helpsub->add( iv_txt = 'Documentation'
                     iv_act = c_actions-documentation ) ##NO_TEXT.
    lo_helpsub->add( iv_txt = 'Explore'
                     iv_act = zif_abapgit_definitions=>c_action-go_explore ) ##NO_TEXT.
    lo_helpsub->add( iv_txt = 'Changelog'
                     iv_act = c_actions-changelog ) ##NO_TEXT.

    ro_menu->add( iv_txt = '+ Online'
                  iv_act = zif_abapgit_definitions=>c_action-repo_newonline ) ##NO_TEXT.
    ro_menu->add( iv_txt = '+ Offline'
                  iv_act = zif_abapgit_definitions=>c_action-repo_newoffline ) ##NO_TEXT.

    ro_menu->add( iv_txt = 'Advanced'
                  io_sub = lo_advsub ) ##NO_TEXT.
    ro_menu->add( iv_txt = 'Help'
                  io_sub = lo_helpsub ) ##NO_TEXT.

  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).
    ms_control-page_menu  = build_main_menu( ).
    ms_control-page_title = 'REPOSITORY LIST'.
  ENDMETHOD.

  METHOD render_scripts.

    CREATE OBJECT ro_html.

    ro_html->zif_abapgit_html~set_title( cl_abap_typedescr=>describe_by_object_ref( me )->get_relative_name( ) ).
    ro_html->add( 'setInitialFocus("filter");' ).
    ro_html->add( 'var gHelper = new RepoOverViewHelper();' ).

  ENDMETHOD.


  METHOD render_content.

    DATA: lt_repos    TYPE zif_abapgit_definitions=>ty_repo_ref_tt,
          lx_error    TYPE REF TO zcx_abapgit_exception,
          li_tutorial TYPE REF TO zif_abapgit_gui_renderable,
          lo_repo     LIKE LINE OF lt_repos.

    CREATE OBJECT ri_html TYPE zcl_abapgit_html.
    gui_services( )->get_hotkeys_ctl( )->register_hotkeys( me ).

    IF mo_repo_overview IS INITIAL.
      CREATE OBJECT mo_repo_overview TYPE zcl_abapgit_gui_repo_over.
    ENDIF.

    ri_html->add( mo_repo_overview->zif_abapgit_gui_renderable~render( ) ).

  ENDMETHOD.


  METHOD test_changed_by.

    DATA: ls_tadir TYPE zif_abapgit_definitions=>ty_tadir,
          lv_user  TYPE xubname,
          ls_item  TYPE zif_abapgit_definitions=>ty_item.


    ls_tadir = zcl_abapgit_ui_factory=>get_popups( )->popup_object( ).
    IF ls_tadir IS INITIAL.
      RETURN.
    ENDIF.

    ls_item-obj_type = ls_tadir-object.
    ls_item-obj_name = ls_tadir-obj_name.

    lv_user = zcl_abapgit_objects=>changed_by( ls_item ).

    MESSAGE lv_user TYPE 'S'.

  ENDMETHOD.


  METHOD zif_abapgit_gui_event_handler~on_event.

    DATA: lv_key           TYPE zif_abapgit_persistence=>ty_value,
          li_repo_overview TYPE REF TO zif_abapgit_gui_renderable,
          li_main_page     TYPE REF TO zcl_abapgit_gui_page_main.

    CASE iv_action.
      WHEN c_actions-abapgit_home.
        CLEAR mv_repo_key.
        ev_state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN c_actions-select.

        lv_key = iv_getdata.

        zcl_abapgit_persistence_user=>get_instance( )->set_repo_show( lv_key ).

        TRY.
            zcl_abapgit_repo_srv=>get_instance( )->get( lv_key )->refresh( ).
          CATCH zcx_abapgit_exception ##NO_HANDLER.
        ENDTRY.

        mv_repo_key = lv_key.
        CREATE OBJECT ei_page TYPE zcl_abapgit_gui_page_view_repo
        EXPORTING iv_key = lv_key.
        ev_state = zcl_abapgit_gui=>c_event_state-new_page.

      WHEN zif_abapgit_definitions=>c_action-change_order_by.

        mo_repo_overview->set_order_by( zcl_abapgit_gui_chunk_lib=>parse_change_order_by( iv_getdata ) ).
        ev_state = zcl_abapgit_gui=>c_event_state-re_render.

      WHEN zif_abapgit_definitions=>c_action-direction.

        mo_repo_overview->set_order_direction( zcl_abapgit_gui_chunk_lib=>parse_direction( iv_getdata ) ).
        ev_state = zcl_abapgit_gui=>c_event_state-re_render.

      WHEN c_actions-apply_filter.

        mo_repo_overview->set_filter( it_postdata ).
        ev_state = zcl_abapgit_gui=>c_event_state-re_render.

      WHEN c_actions-changed_by.
        test_changed_by( ).
        ev_state = zcl_abapgit_gui=>c_event_state-no_more_act.

      WHEN c_actions-documentation.
        zcl_abapgit_services_abapgit=>open_abapgit_wikipage( ).
        ev_state = zcl_abapgit_gui=>c_event_state-no_more_act.

      WHEN zif_abapgit_definitions=>c_action-go_explore.
        zcl_abapgit_services_abapgit=>open_dotabap_homepage( ).
        ev_state = zcl_abapgit_gui=>c_event_state-no_more_act.

      WHEN c_actions-changelog.
        zcl_abapgit_services_abapgit=>open_abapgit_changelog( ).
        ev_state = zcl_abapgit_gui=>c_event_state-no_more_act.

      WHEN OTHERS.

        super->zif_abapgit_gui_event_handler~on_event(
          EXPORTING
            iv_action    = iv_action
            iv_getdata   = iv_getdata
            it_postdata  = it_postdata
          IMPORTING
            ei_page      = ei_page
            ev_state     = ev_state ).

    ENDCASE.

  ENDMETHOD.


  METHOD zif_abapgit_gui_hotkeys~get_hotkey_actions.

    DATA: ls_hotkey_action LIKE LINE OF rt_hotkey_actions.

    ls_hotkey_action-ui_component = 'Main'.

    ls_hotkey_action-description   = |abapGit settings|.
    ls_hotkey_action-action = zif_abapgit_definitions=>c_action-go_settings.
    ls_hotkey_action-hotkey = |x|.
    INSERT ls_hotkey_action INTO TABLE rt_hotkey_actions.

    ls_hotkey_action-description   = |Add online repository|.
    ls_hotkey_action-action = zif_abapgit_definitions=>c_action-repo_newonline.
    ls_hotkey_action-hotkey = |n|.
    INSERT ls_hotkey_action INTO TABLE rt_hotkey_actions.

  ENDMETHOD.

ENDCLASS.
