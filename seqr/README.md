
**Misc notes**:
  chromosome names are represented without the 'chr'

**Tech stack**:

- server:
  - python3.6
  - Django

- web ui:
  - React.js
  - Redux
  
**Dev notes**:

- server (python3) 
    - code docs:
        - autogenerated using [Sphinx-apidoc](http://www.sphinx-doc.org/en/1.4.9/man/sphinx-apidoc.html)
        - doc strings style:
        ```
        """Method summary.
        
        Method description. 
        
        Args:
            path (str): The path of the file to wrap
            field_storage (FileStorage): The :class:`FileStorage` instance to wrap
            temporary (bool): Whether or not to delete the file when the File
               instance is destructed
        
        Returns:
            (HTTPResponse): A buffered writable file descriptor
        """
        ```
        
        based on Google python style guide: [see detailed description](http://www.sphinx-doc.org/en/1.5.1/ext/napoleon.html#module-sphinx.ext.napoleon)
       - to generate docs, run:  
         `make docs` 
    
    - linting and style:
       - pylint is too strict.   
         pyflakes provides useful code inspections, and maybe be useful in the future. Most of it's 
         features also exist in IntelliJ under Analyze > Inspect Code... 
        
    - tests:
        - [Django testing reference](https://docs.djangoproject.com/en/1.10/topics/testing/).
        - to run tests, run:  `make test`   
          
    - design notes:
        - datasets, individuals, families can only exist in 0 or 1 projects. Adding them to 2 or more
          projects would add a lot of complexity with either creating copies of the mutable fields or
          managing permissions and edits from different projects 
         
        - permissions
            - Django-Guardian is a popular django auth extension for object-level permissions.
            - Objects for which permissions can be set via Guardian: Project (uses Groups), LocusList, Individual, and Dataset
            - use CAN_VIEW Project permissions group to add LocusLists (and any other objects that have their own permissions) to projects, since
              you anyway have to grant CAN_VIEW permissions for this object to the project's CAN_VIEW group of users, it seems fine to also just
              use it to decide which gene lists are visible to the user when they search a project. This mechanism can be used to share any
               object with a project.
                    
            - Permissions levels will be CAN_VIEW, CAN_EDIT, IS_OWNER, and (similar to linux), when
              somebody is granted CAN_EDIT permissions, the code needs to also give then CAN_VIEW permissions explicitly since 
              Guardian permissions are binary (like linux rwx flags).
            
        - concurrent editing
            - Since seqr allows multiple users to share and modify content, concurrent modification 
            where users overwrite eachother's edits must be prevented. 
            Since users can connect/disconnect arbitrarily, locking is not a good solution. Instead, 
            we'll use optimistic concurrency where all objects that can be shared and modified 
            will also be given a `last_modified_date` field. When an object is read from 
            the database, a `database_read_date` field will be attached to the data packet before it's 
            sent to client. If the user then modifies the data in some way and hits `Save`, 
            this `database_read_date` will be sent back to the server along with the modified values. 
            The server will then check and reject the modification if its `database_read_date` is 
            now older than the `last_modified_date` in the database.
          
- web ui (javascript: ECMA2017 / css / jsx)
    - code docs
    - tests
    
    


**Links**:
- [Django](https://docs.djangoproject.com/en/1.10/ref/) - Django reference
- [React.js](https://facebook.github.io/react/docs/hello-world.html) - Facebook's tutorial and reference
- [JSX](https://facebook.github.io/react/docs/jsx-in-depth.html)
- [Intro to Redux](https://egghead.io/courses/building-react-applications-with-idiomatic-redux) - by Dan Abramov, the creator of Redux
- [Rest API design](http://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api) until we switch to GraphQL
- [SemanticUI](http://react.semantic-ui.com) 