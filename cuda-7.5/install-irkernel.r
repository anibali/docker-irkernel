library("devtools")
install_local("./rzmq")
install.packages(c('repr','IRkernel','IRdisplay'),
  repos=c('http://irkernel.github.io/', 'http://cran.r-project.org'),
  type='source')
IRkernel::installspec()
