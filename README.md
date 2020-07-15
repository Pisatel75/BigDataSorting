# BigDataSorting
Experimental algorithm of Big Data sorting. 
The application is able to alphabetically sort any big ASCII files with CRLF ending of its strings.

ATTENTION! The application requires sufficient free space on your hard drive and a good speed of reading and writing files!

How its work.
Place the data.txt file in the application executable directory and run the application. Click the start button. 
The result of sorting will be in the same directory in the form of two files: zero.txt and result.txt, 
where zero.txt indicated the number of zero records and the result.txt is alphabetically sorted text.

The application creates and launches four additional computational threads and uses the "quick sort" algorithm for sorting. 
A minimum amount of RAM is required, however, there are high requirements for the volume and speed of the HDD or SSD.

Be careful when using the application to sort very large files! 
There is a risk of damage to the file system when the hard drive becomes full! 
The amount of free space on your hard drive must be at least three times the size of the sorted file!

Best Regards,
Dmitry Uspenskiy
