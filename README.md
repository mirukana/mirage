# harmonyqml

## Dependencies setup

### [pyotherside](https://github.com/thp/pyotherside)

	git clone https://github.com/thp/pyotherside
	cd pyotherside
	qmake
	make
	sudo make install

After this, verify the permissions of the installed plugin files.

	sudo chmod 644 /usr/lib/qt5/qml/io/thp/pyotherside/*
	sudo chmod 755 /usr/lib/qt5/qml/io/thp/pyotherside/*.so
