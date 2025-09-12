This directory contains lua modules that are shared among different Confgen templates or need to
contain some sort of state to be kept between invocations of one template. These are `require`'d in
their respective templates and should be named after the program being configured or their purpose
for universal ones.
