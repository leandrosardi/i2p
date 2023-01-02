BlackStack::Extensions::add ({
    # descriptive name and descriptor
    :name => 'i2p',
    :description => 'Simple Invoicing & Payments Processing.',

    # setup the url of the repository for installation and updates
    :repo_url => 'https://github.com/leandrosardi/i2p',
    :repo_branch => 'master',

    # define version with format <mayor>.<minor>.<revision>
    :version => '0.0.1',

    # define the name of the author
    :author => 'leandrosardi',

    # what is the section to add this extension in either the top-bar, the footer, the dashboard.
    :services_section => 'Services',
    # show this extension as a service in the top bar?
    :show_in_top_bar => false,
    # show this extension as a service in the footer?
    :show_in_footer => false,
    # show this extension as a service in the dashboard?
    :show_in_dashboard => false,

    # add some screens of this extension to the account settings of your SaaS.
    :setting_screens => [
        # add a link in section `Billing & Finances` of the `/settings` screen, with a caption `Invoices`, and linking to the screen `/settings/invoices`. The source code of the screen `/settings/invoices` is copied from the file `/vews/invoices.erb` in the extension's folder. 
        { :section => 'Billing & Finances', :label => 'Invoices', :screen => :invoices },
#        { :section => 'Billing & Finances', :label => 'PayPal Subscriptions', :screen => :subscriptions },
#        { :section => 'Billing & Finances', :label => 'Transactions', :screen => :transactions },
    ],
})