set(CPACK_RPM_PACKAGE_NAME "instant-a704f-mouse-utilities")
set(CPACK_RPM_FILE_NAME RPM-DEFAULT)
set(CPACK_RPM_PACKAGE_RELEASE 1)
set(CPACK_RPM_PACKAGE_LICENSE "MIT")
set(CPACK_RPM_PACKAGE_URL "${PROGRAM_SRC_URL}")
set(CPACK_RPM_PACKAGE_DESCRIPTION "Configure lighting, buttons, scrolling and DPI on supported Instant A704/A704F mice.")
set(CPACK_RPM_PACKAGE_RELOCATABLE OFF)
set(CPACK_RPM_EXCLUDE_FROM_AUTO_FILELIST_ADDITION
    /usr/lib/udev /usr/lib/udev/rules.d
    /usr/share/icons /usr/share/icons/hicolor
    /usr/share/icons/hicolor/32x32 /usr/share/icons/hicolor/32x32/apps
)
set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/script/rpm-post-install")
set(CPACK_RPM_POST_UNINSTALL_SCRIPT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/script/rpm-post-install")
