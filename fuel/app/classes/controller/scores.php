<?php
/**
 * Materia
 * License outlined in licenses folder
 */

class Controller_Scores extends Controller
{
	use Trait_CommonControllerTemplate;

	public function get_show($inst_id)
	{
		// locate instance
		$instances = Materia\Api::widget_instances_get([$inst_id]);
		if ( ! isset($instances[0])) throw new HttpNotFoundException;

		$inst = $instances[0];
		// not allowed to play the widget
		if ( ! $inst->playable_by_current_user())
		{
			Session::set_flash('notice', 'Please log in to view your scores.');
			Response::redirect(Router::get('login').'?redirect='.urlencode(URI::current()));
		}

		Css::push_group(['core', 'scores']);

		Js::push_group(['angular', 'materia', 'student', 'labjs']);

		$token = \Input::get('token', false);
		if ($token)
		{
			Js::push_inline('var LAUNCH_TOKEN = "'.$token.'";');
		}

		$this->theme->get_template()
			->set('title', 'Score Results')
			->set('page_type', 'scores');

		$this->theme->set_partial('footer', 'partials/angular_alert');
		$this->theme->set_partial('content', 'partials/score/full');
	}

	public function get_show_embedded($inst_id)
	{
		$this->_header = 'partials/header_empty';
		$this->get_show($inst_id);
	}
}
