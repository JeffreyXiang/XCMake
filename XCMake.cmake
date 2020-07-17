function(Xi_printList)
	cmake_parse_arguments("ARG" "" "TITLE;PREFIX" "LIST" ${ARGN})
	if(NOT ${ARG_TITLE} STREQUAL "")
		message(STATUS ${ARG_TITLE})
	endif()
	foreach(str ${ARG_LIST})
		message(STATUS "${ARG_PREFIX}${str}")
	endforeach()
endfunction()

function(Xi_addAllSubDirRaw path)
	file(GLOB_RECURSE children LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${path}/*)
	set(dirs "")
	foreach(item ${children})
		if(IS_DIRECTORY ${item} AND EXISTS "${item}/CMakeLists.txt")
			list(APPEND dirs ${item})
		endif()
	endforeach()
	Xi_printList(TITLE "directories:" PREFIX "- " LIST ${dirs})
	foreach(dir ${dirs})
		add_subdirectory(${dir})
	endforeach()
endfunction()

function(Xi_addAllSubDir)
	Xi_addAllSubDirRaw(src)
endfunction()

function(Xi_groupSrcs)
	cmake_parse_arguments("ARG" "" "" "SOURCES" ${ARGN})
	foreach(file ${ARG_SOURCES})
		get_filename_component(filePath "${file}" PATH)
		file(RELATIVE_PATH filePathRel ${CMAKE_CURRENT_SOURCE_DIR} "${filePath}")
		if(MSVC)
			string(REPLACE "/" "\\" filePathRelMSVC "${filePathRel}")
		endif()
		source_group("${filePathRelMSVC}" FILES "${file}")
	endforeach()
endfunction()

function(Xi_groupAllSrcs)
	file(GLOB_RECURSE srcs ${CMAKE_CURRENT_SOURCE_DIR}/*)
	Xi_groupSrcs(SOURCES ${srcs})
endfunction()

function(Xi_getTargetNameRaw rst targetPath)
	file(RELATIVE_PATH targetRelPath "${PROJECT_SOURCE_DIR}/src" "${targetPath}")
	string(REPLACE "/" "_" targetName "${PROJECT_NAME}/${targetRelPath}")
	set(${rst} ${targetName} PARENT_SCOPE) 
endfunction()

function(Xi_getTargetName rst)
	Xi_getTargetNameRaw(targetName ${CMAKE_CURRENT_SOURCE_DIR})
	set(${rst} ${targetName} PARENT_SCOPE) 
endfunction()

function(Xi_addTargetRaw)
	cmake_parse_arguments("ARG" "" "MODE;QT" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})
	file(RELATIVE_PATH targetRelPath "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
	set(folderPath "${PROJECT_NAME}/${targetRelPath}")
	Xi_getTargetName(targetName)
	
	list(LENGTH ARG_SOURCES sourceNum)
	if(${sourceNum} EQUAL 0)
		file(GLOB_RECURSE ARG_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*)
		Xi_groupSrcs(SOURCES ${ARG_SOURCES})
		list(LENGTH ARG_SOURCES sourceNum)
		if(sourcesNum EQUAL 0)
			message(WARNING "Target [${targetName}] has no source")
			return()
		endif()
	endif()
	
	message(STATUS "")
	message(STATUS "---------- New Target ----------")
	message(STATUS "- name: ${targetName}")
	message(STATUS "- folder : ${folderPath}")
	message(STATUS "- mode: ${ARG_MODE}")
	Xi_printList(LIST ${ARG_SOURCES}
		TITLE "- sources:"
		PREFIX "    ")
	
	list(LENGTH ARG_LIBS_GENERAL generalLibNum)
	list(LENGTH ARG_LIBS_DEBUG debugLibNum)
	list(LENGTH ARG_LIBS_RELEASE releaseLibNum)
	if(${debugLibNum} EQUAL 0 AND ${releaseLibNum} EQUAL 0)
		if(NOT ${generalLibNum} EQUAL 0)
		Xi_printList(LIST ${ARG_LIBS_GENERAL}
			TITLE  "- lib:"
			PREFIX "    ")
		endif()
	else()
		message(STATUS "- libs:")
		Xi_printList(LIST ${ARG_LIBS_GENERAL}
			TITLE  "  - general:"
			PREFIX "      ")
		Xi_printList(LIST ${ARG_LIBS_DEBUG}
			TITLE  "  - debug:"
			PREFIX "      ")
		Xi_printList(LIST ${ARG_LIBS_RELEASE}
			TITLE  "  - release:"
			PREFIX "      ")
	endif()
	
	# add target
	if(${ARG_MODE} STREQUAL "EXE")
		add_executable(${targetName} ${ARG_SOURCES})
		if(MSVC)
			set_target_properties(${targetName} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")
			set_target_properties(${targetName} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
		endif()
	elseif(${ARG_MODE} STREQUAL "LIB")
		add_library(${targetName} STATIC ${ARG_SOURCES})
	elseif(${ARG_MODE} STREQUAL "DLL")
		add_library(${targetName} SHARED ${ARG_SOURCES})
	else()
		message(FATAL_ERROR "mode [${ARG_MODE}] is not supported")
		return()
	endif()
	
	# folder
	set_target_properties(${targetName} PROPERTIES FOLDER ${folderPath})
	
	foreach(lib ${ARG_LIBS_GENERAL})
		target_link_libraries(${targetName} general ${lib})
	endforeach()
	foreach(lib ${ARG_LIBS_DEBUG})
		target_link_libraries(${targetName} debug ${lib})
	endforeach()
	foreach(lib ${ARG_LIBS_RELEASE})
		target_link_libraries(${targetName} optimized ${lib})
	endforeach()
	install(TARGETS ${targetName}
		RUNTIME DESTINATION "bin"
		ARCHIVE DESTINATION "lib"
		LIBRARY DESTINATION "lib")
endfunction()

function(Xi_addTarget)
	cmake_parse_arguments("ARG" "" "MODE" "LIBS" ${ARGN})
	Xi_addTargetRaw(MODE ${ARG_MODE} LIBS_GENERAL ${ARG_LIBS})
endfunction()
